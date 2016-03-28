require 'net/http'
require 'uri'
require 'json'
require 'elasticsearch'

# Query Elasticsearch with arbitrary search criteria

module NagiosHerald
  module Helpers
    class ElasticsearchQuery
      include NagiosHerald::Logging

      attr_reader :query

      # Public: Initialize a new ElasticsearchQuery object.
      #
      # options - A hash of various options one may want when initializing this object.
      #
      # Example:
      #   options = {
      #     "index"       => "wutang",
      #     "time_period" => "1h",
      #     "num_results" => "50"
      #   }
      #   elasticsearch_helper = NagiosHerald::Helper::ElasticsearchQuery(options)
      #
      # Returns a new ElasticsearchQuery object.
      def initialize(options={})
        today = Time.now.strftime("%Y.%m.%d")
        @elasticsearch_index = options[:index] ? options[:index] : "logstash-#{today}"
        @elasticsearch_time_period = options[:time_period] ? options[:time_period] : "1h"
        if options[:num_results].nil?
          @elasticsearch_num_results = Config.config['elasticsearch']['num_results'] ? Config.config['elasticsearch']['num_results'] : 10
        else
          @elasticsearch_num_results = options[:num_results]
        end
        @elasticsearch_result_field_truncate = Config.config['elasticsearch']['result_field_truncate'] ? Config.config['elasticsearch']['result_field_truncate'] : nil

        # Pull the elasticsearch URI from the config.
        elasticsearch_url = Config.config['elasticsearch']['url']

        # Parse the URI.
        uri = URI.parse(elasticsearch_url)
        @elasticsearch_host = uri.host
        @elasticsearch_port = uri.port
        @elasticsearch_uri  = uri.request_uri

        @es_client = Elasticsearch::Client.new hosts: ["#{@elasticsearch_host}:#{@elasticsearch_port}"], reload_connections: true
      end

      # Public: Queries Elasticsearch using a simple Lucene query string.
      # Will package the query string into JSON for Elasticsearch to consume.
      #
      # query_string - The Lucene query to execute.
      #
      # Example:
      #   query_string = "type:apache_access_log AND http_status:404"
      #   elasticsearch_helper.query_from_string(query_string)
      #
      # Returns the results of the query.
      def query_from_string(query_string)

        # Strip leading and following single quotes from query if present
        query_string = query_string[1..-1] if query_string[0] == "'"
        query_string = query_string[0..-2] if query_string[-1] == "'"

        @query_json = {
            "from" => 0,
            "size" => @elasticsearch_num_results,
            "query" => {
                "filtered" => {
                    "query" => {
                        "bool" => {
                            "should" => [
                                {
                                    "query_string" => {
                                        "query" => "#{query_string}",
                                        "default_operator" => "AND",
                                        "lowercase_expanded_terms" => false
                                    }
                                }
                            ]
                        }
                    },
                    "filter" => {
                        "bool" => {
                            "must" => [
                                {
                                    "match_all" => {}
                                },
                                {
                                    "range" => {
                                        "index_timestamp" => {
                                            "from" => "now-#{@elasticsearch_time_period}",
                                            "to" => "now"
                                        }
                                    }
                                }
                            ]
                        }
                    }
                }
            }
        }
        results = run_elasticsearch_query(@query_json)
        if results
          truncate_results_fields(results)
        end
      end

      # Public: Queries Elasticsearch using JSON found in a file.
      #
      # query_file - Full path to a file containing an Elasticsearch query in JSON.
      #
      # Example:
      #   query_file = "/usr/local/elasticsearch/wutang.json"
      #   elasticsearch_helper.query_from_file(query_file)
      #
      # Returns the results of the query.
      def query_from_file(query_file)
        if File.exists? query_file
          begin
            @query_json = JSON.parse(File.readlines(query_file).join)
          rescue Exception => e
            logger.error "Failed to parse JSON query file - #{e.message}"
            e.backtrace.each do |line|
              logger.error "#{line}"
            end
            return nil
          end
        else
          logger.error "Query file '#{query_file}' does not exist! Cannot execute query."
          return nil
        end

        results = run_elasticsearch_query(@query_json)
        if results
          truncate_results_fields(results)
        end
      end

      # Public: Executes an Elasticsearch query.
      #
      # query_json - A JSON-encoded Elasticsearch query.
      #
      # Example:
      #   query_json = '{"query": {...}, "size": "10", ...}'
      #   results = run_elasticsearch_query(query_json)
      #
      # Returns the results of the query.
      def run_elasticsearch_query(query_json)
        begin
          return @es_client.search index: @elasticsearch_index, body: query_json
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
          logger.error "Failed to execute Elasticsearch query - #{e.message}"
          e.backtrace.each do |line|
            logger.error "#{line}"
          end
          return nil
        rescue Exception => e
          logger.error "Could not connect to Elasticsearch - #{e.message}"
          e.backtrace.each do |line|
            logger.error "#{line}"
          end
          return nil
        end
      end

      # Public: Truncate the field values in results.
      # Some fields can have very long values that aren't conducive to
      # media like email and SMS. We can optionaly truncate them and still get
      # important data through.
      #
      # results - Results from an Elasticsearch query executed by run_elasticsearch_query()
      #
      # Example:
      #   results = run_elasticsearch_query(@query_json)
      #   if results
      #     truncate_results_fields(results)
      #   end
      #
      # Returns the results of the query with truncated fields.
      def truncate_results_fields(results)
        results["hits"]["hits"].each do |result|
          result["_source"].each do |field_name,field_value|
            result["_source"][field_name] = field_value[0..@elasticsearch_result_field_truncate] if @elasticsearch_result_field_truncate
          end
        end
        return results
      end
    end
  end
end

