require 'nagios-herald/helpers/base'

require 'net/http'
require 'uri'
require 'json'

# Query Splunk with arbitrary search criteria

module NagiosHerald
  class Helper
    class SplunkQuery < Helper
      #include NagiosHerald::Logging

      # Public: Initialize a new SplunkQuery object.
      #
      # query - A string representing the query to send to Splunk.
      # index - Optional index to specify (else Splunk defaults to all indexes
      #   available to the authenticated user).
      # output - The output format we'd like (i.e. csv, json, xml); defaults
      #   to json.
      #
      # Example:
      #
      # splunk_query = NagiosHerald::Helper::SplunkQuery.new('sourcetype=perf_log page=index.html')
      # splunk_query = NagiosHerald::Helper::SplunkQuery.new('transaction_state=paid', {:index => 'get_paid'})
      # splunk_query = NagiosHerald::Helper::SplunkQuery.new('source=nagios-herald.log alert_type=host', {:output => 'csv'})
      #
      # Returns a new SplunkQuery object.
      def initialize(query, options={})
        @splunk_query = query
        @splunk_index = options[:index] ? options[:index] : nil
        @splunk_output = options[:output] ? options[:output] : 'json'

        # Pull the Splunk URI, username, and password from the config.
        splunk_url = Config.config['splunk']['url']
        @splunk_username = Config.config['splunk']['username']
        @splunk_password = Config.config['splunk']['password']

        # Parse the URI.
        uri = URI.parse(splunk_url)
        @splunk_host = uri.host
        @splunk_port = uri.port
        @splunk_uri  = uri.request_uri
      end

      # Public: Generate the parameters for the Splunk query.
      #
      # Example:
      #
      # parameters = splunk_query.parameters
      #
      # Returns the Splunk query parameters.
      def parameters
        # Earliest time we should look for events; defaults to 7 days ago.
        earliest_time = Config.config['splunk']['earliest_time'] ?
          Config.config['splunk']['earliest_time'] :
          '7d'

        # Latest time we should look for events; defaults to now.
        latest_time = Config.config['splunk']['latest_time'] ?
          Config.config['splunk']['latest_time'] :
          'now'

        # Maximum results returned; defaults to 100.
        max_results = Config.config['splunk']['max_results'] ?
          Config.config['splunk']['max_results'] :
          100

        params = {
            'exec_mode'     => 'oneshot',
            'earliest_time' => "-#{earliest_time}",
            'latest_time'   => latest_time,
            'output_mode'   => @splunk_output,
            'count'         => max_results
        }
        if @splunk_index.nil?
          params['search'] = "search #{@splunk_query}"
        else
          params['search'] = "search index=#{@splunk_index} " + @splunk_query
        end

        params
      end

      # Public: Queries Splunk.
      #
      # Example:
      #
      # results = splunk_query.query
      #
      # Returns the results of the query in the requested format, nil otherwise.
      def query
        http = Net::HTTP.new( @splunk_host, @splunk_port )
        http.use_ssl = true
        http.open_timeout = 1
        http.read_timeout = 2
        http.ssl_timeout = 1
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE    # don't validate the cert
        request = Net::HTTP::Post.new( @splunk_uri )
        request.basic_auth( @splunk_username, @splunk_password )
        request.set_form_data( parameters )
        begin
          response = http.request( request )
        rescue Exception => e
          logger.warn "Failed to send request: #{e.message}"
          return nil
        end

        if response.code.eql?( "200" )
          response.body
        else
          logger.warn "Splunk query failed with HTTP #{response.code}: #{response.message}"
          logger.warn response.body
          return nil
        end
      end

    end
  end
end

