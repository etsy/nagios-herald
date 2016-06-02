# CheckGraphiteGraph formatter
# Downloads the Graphite graph used to trigger the alert.
# Also downloads an historical graph of the last 24 hours for comparison.

module NagiosHerald
  class Formatter
    class CheckGraphiteGraph < NagiosHerald::Formatter
      include NagiosHerald::Logging

      # Public: Retrieves Graphite graphs for the endpoint the check queried.
      # url - The URL for the Graphite endpoint the check queried.
      # Returns the file names of all retrieved graphs. These can be attached to the message.
      def get_graphite_graphs(url)
        begin
          graphite = NagiosHerald::Helper::GraphiteGraph.new
          show_historical = true
          graphs =  graphite.get_graph(url, @sandbox, show_historical)
          return graphs
        rescue Exception => e
          logger.error "Exception encountered retrieving Graphite graphs - #{e.message}"
          e.backtrace.each do |line|
            logger.error "#{line}"
          end
          return []
        end
      end

      # Public: Overrides Formatter::Base#additional_info.
      # Returns nothing. Updates the formatter content hash.
      def additional_info
        section = __method__
        output = get_nagios_var("NAGIOS_#{@state_type}OUTPUT")
        # Output is formatted like: Current value: 18094.25, warn threshold: 100.0, crit threshold: 1000.0
        add_text(section, "Additional Info:\n #{unescape_text(output)}\n\n") if output
        output_match = output.match(/Current value: (?<current_value>[^,]*), warn threshold: (?<warn_threshold>[^,]*), crit threshold: (?<crit_threshold>[^,]*)/)
        if output_match
          add_html(section, "Current value: <b><font color='red'>#{output_match['current_value']}</font></b>, warn threshold: <b>#{output_match['warn_threshold']}</b>, crit threshold: <b><font color='red'>#{output_match['crit_threshold']}</font></b><br><br>")
        else
          add_html(section, "<b>Additional Info</b>:<br> #{output}<br><br>") if output
        end

        # Get Graphite graphs.
        # Extract the Graphite URL from NAGIOS_SERVICECHECKCOMMAND
        service_check_command = get_nagios_var("NAGIOS_SERVICECHECKCOMMAND")
        url = service_check_command.split(/!/)[-1].gsub(/'/, '')
        graphite_graphs = get_graphite_graphs(url)
        from_match = url.match(/from=(?<from>[^&]*)/)
        if from_match
          add_html(section, "<b>View from '#{from_match['from']}' ago</b><br>")
        else
         add_html(section, "<b>View from the time of the Nagios check</b><br>")
        end
        add_attachment graphite_graphs[0]    # The original graph.
        add_html(section, %Q(<img src="#{graphite_graphs[0]}" alt="graphite_graph" /><br><br>))
        add_html(section, '<b>24-hour View</b><br>')
        add_attachment graphite_graphs[1]    # The 24-hour graph.
        add_html(section, %Q(<img src="#{graphite_graphs[1]}" alt="graphite_graph" /><br><br>))
      end

    end
  end
end
