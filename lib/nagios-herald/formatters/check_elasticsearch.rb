# CheckElasticsearch formatter

require 'erb'

module NagiosHerald
  class Formatter
    class CheckElasticsearch < NagiosHerald::Formatter
      include NagiosHerald::Logging

      # Public: Overrides Formatter::Base#additional_info.
      # Calls on methods defined in this class to generate stack bars and download
      # Ganglia graphs.
      #
      # Returns nothing. Updates the formatter content hash.
      def additional_info
        section = __method__  # this defines the section key in the formatter's content hash
        service_output = get_nagios_var("NAGIOS_SERVICECHECKCOMMAND")
        command_components =  parse_command(service_output)

        # The aggregation level limit for which we can render results
        agg_level_limit = 3

        elasticsearch_helper = NagiosHerald::Helper::ElasticsearchQuery.new({ :time_period => command_components[:time_period]})
        results = get_elasticsearch_results(elasticsearch_helper, command_components[:query])

        # Handle the case when an exception is thrown inside get_elasticsearch_results
        if results.nil? or results.empty?
          add_text(section, "Something went wrong while getting Elasticsearch results\n\n")
          return
        end

        if results["hits"]["hits"].empty? && results["aggregations"]
          # We have aggregations

          query_agg_data = elasticsearch_helper.query["aggregations"] || elasticsearch_helper.query["aggs"]

          agg_depth_level = 1 + agg_depth(query_agg_data)

          # We can't cope with more than 3 level deep aggregates
          if agg_depth_level > agg_level_limit
            #Add error text to the alert and return straight away
            add_text(section, "Error - query contains #{agg_depth_level} levels of aggregation - more than #{agg_level_limit} levels are not supported by this plugin\n")
            return
          end

          agg_field_name = query_agg_data.keys.first

          html_output = generate_table_from_buckets(results["aggregations"][agg_field_name]["buckets"])
        else
          # We have normal search results
          html_output = generate_html_output(results["hits"]["hits"])
        end

        add_html(section, html_output)
      end

      # Public: Overrides Formatter::Base#additional_details.
      #
      # Returns nothing. Updates the formatter content hash.
      def additional_details

      end

      # Public: Formats the notes information for this alert.
      # Generates text and HTML output.
      def notes
          super()

          section = __method__
          text = ""
          html = ""

          service_output = get_nagios_var("NAGIOS_SERVICECHECKCOMMAND")
          command_components =  parse_command(service_output)

          frontend_url_format = NagiosHerald::Config.config['elasticsearch']['frontend_url']

          if !frontend_url_format.nil? and !frontend_url_format.empty?
            bounds = get_frontend_bounds_from_time_period(command_components[:time_period])
            query_string = command_components[:query]

            # Strip leading and following single quotes from query if present
            query_string = query_string[1..-1] if query_string[0] == "'"
            query_string = query_string[0..-2] if query_string[-1] == "'"

            frontend_url = frontend_url_format % { :query => ERB::Util.url_encode(query_string), :to => bounds[:to], :from => bounds[:from] }

            text += "Frontend URL: #{frontend_url}\n\n"
            html += "<b>Frontend URL</b>: #{frontend_url}<br><br>"
          end

          add_text(section, text)
          add_html(section, html)
      end

      private

      def parse_command(service_command)
        command_components = service_command.split("!")
        {
            :command => command_components[0],
            :query => command_components[1],
            :warn_threshold => command_components[2],
            :crit_threshold => command_components[3],
            :time_period => command_components[4]
        }
      end

      # Private: Takes in a string like '20m'
      # returns (utc timestamp - '60m' , utc timestamp + '60m')
      def get_frontend_bounds_from_time_period(time_period)
        parts = /(\d+)(\w+)/.match(time_period)

        if parts.nil? or parts.size < 3 or parts[2].size < 1
            return {
                :from => time_period,
                :to => 'now',
            }
        end

        delta = (parts[1].to_i) * 3
        period = 0

        # really naive parsing of a time period
        case parts[2][0]
            when 's'
                period = 1
            when 'm'
                period = 60
            when 'h'
                period = 60 * 60
            when 'd'
                period = 60 * 60 * 24
            when 'w'
                period = 60 * 60 * 24 * 7
            else
                period = 60
        end

        {
            :from => Time.now.to_i - period * delta,
            :to   => Time.now.to_i
        }
      end

      def agg_depth(agg_data)
        agg_level = 0
        if agg_data.kind_of?(String)
          agg_level = agg_data.include?("aggs") || agg_data.include?("aggregations") ? 1 : 0
        else
          agg_data.each do |k,v|
            this_level = k.include?("aggs") || k.include?("aggregations") ? 1 : 0
            agg_level = this_level + agg_depth(v)
          end
        end
        agg_level
      end

      def get_elasticsearch_results(elasticsearch_helper, query)
        begin
          if query.include?(".json")
            elasticsearch_helper.query_from_file(query)
          else
            elasticsearch_helper.query_from_string(query)
          end
        rescue Exception => e
          logger.error "Exception encountered retrieving Elasticsearch Query - #{e.message}"
          e.backtrace.each do |line|
            logger.error "#{line}"
          end
          return []
        end
      end

      def generate_html_output(results)
        output_prefix = "<table border='1' cellpadding='0' cellspacing='1'>"
        output_suffix = "</table>"

        headers = "<tr>#{results.first["_source"].keys.map{|h|"<th>#{h}</th>"}.join}</tr>"
        result_values = results.map{|r|r["_source"]}

        body = result_values.map{|r| "<tr>#{r.map{|k,v|"<td>#{v}</td>"}.join}</tr>"}.join

        output_prefix + headers + body + output_suffix
      end

      def generate_table_from_buckets(buckets)
        unique_keys = buckets.map{|b|b.keys}.flatten.uniq

        output_prefix = "<table border='1' cellpadding='0' cellspacing='1'>"
        output_suffix = "</table>"
        headers = "<tr>#{unique_keys.map{|h|"<th>#{h}</th>"}.join}</tr>"
        body = buckets.map do |r|
          generate_table_from_hash(r)
        end.join
        output_prefix + headers + body + output_suffix
      end

      def generate_table_from_hash(data,add_headers=false)
        output_prefix = "<table border='1' cellpadding='0' cellspacing='1'>"
        output_suffix = "</table>"
        headers = add_headers ? "<tr>#{data.keys.map{|h|"<th>#{h}</th>"}.join}</tr>" : ""
        body = "<tr>#{data.map do |k,v|
            if v.kind_of?(Hash)
              if v.has_key?("buckets")
                "<td>#{generate_table_from_buckets(v["buckets"])}</td>"
              else
                "<td>#{generate_table_from_hash(v,true)}</td>"
              end
            else
              "<td>#{v}</td>"
            end
        end.join}</tr>"

        if add_headers
          output_prefix + headers + body + output_suffix
        else
          body
        end
      end
    end
  end
end
