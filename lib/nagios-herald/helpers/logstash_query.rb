require 'net/http'
require 'uri'
require 'json'
require 'elasticsearch'

# Query Logstash with arbitrary search criteria

module NagiosHerald
  module Helpers
    class LogstashQuery

      # Public: Initialize a new LogstashQuery object.
      #
      # query - A string representing the query to send to Logstash.
      # index - Optional index to specify (else Splunk defaults to all indexes
      #   available to the authenticated user).
      # output - The output format we'd like (i.e. csv, json, xml); defaults
      #   to json.
      #
      # Example:
      #
      # NEEDS EXAMPLES
      #
      # Returns a new LogstashQuery object.
      def initialize(options={})
        today = Time.now.strftime("%Y.%m.%d")
        @logstash_index = options[:index] ? options[:index] : "logstash-#{today}"
        @logstash_time_period = options[:time_period] ? options[:time_period] : "1h"
        @logstash_num_results = options[:num_results] ? options[:num_results] : 10
        @logstash_result_truncate = Config.config['logstash']['result_field_trucate'] ? Config.config['logstash']['result_field_trucate'] : nil

        # Pull the Logstash URI, username, and password from the config.
        logstash_url = Config.config['logstash']['url']

        # Parse the URI.
        uri = URI.parse(logstash_url)
        @logstash_host = uri.host
        @logstash_port = uri.port
        @logstash_uri  = uri.request_uri

        @es = Elasticsearch::Client.new hosts: ["#{@logstash_host}:#{@logstash_port}"], reload_connections: true
      end

      # Public: Queries Logstash.
      #
      # Example:
      #
      # results = logstash_query.query
      #
      # Returns the results of the query in the requested format, nil otherwise.
      def query(query)

        # Strip leading and following single quotes from query if present
        query = query[1..-1] if query[0] == "'"
        query = query[0..-2] if query[-1] == "'"

        query_body = {
            "from" => 0,
            "size" => @logstash_num_results,
            "query" => {
                "filtered" => {
                    "query" => {
                        "bool" => {
                            "should" => [
                                {
                                    "query_string" => {
                                        "query" => "#{query}"
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
                                            "from" => "now-#{@logstash_time_period}",
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
        truncate_results(run_logstash_query(query_body))
        #run_logstash_query(query_body)
      end

      def query_from_file(query_file)
        if File.exists? query_file
          query_body = JSON.parse(File.readlines(query_file).join)
        else
          raise "Query file #{query_file} does not exist"
        end

        truncate_results(run_logstash_query(query_body))
      end

      private

      def run_logstash_query(query_body)
        begin
          return @es.search index: @logstash_index, body: query_body
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
          raise "Elasticsearch doesn't like your query. Please check you escaped it correctly."
        end
      end

      def truncate_results(results)
        results["hits"]["hits"].each{|result|result["_source"].each{|field_name,field_value|result["_source"][field_name] = field_value[0..@logstash_result_truncate]}} if @logstash_result_truncate
        return results
      end
    end
  end
end

