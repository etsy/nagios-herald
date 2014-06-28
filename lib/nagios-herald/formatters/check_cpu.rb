module NagiosHerald
  class Formatter
    class CheckCpu < NagiosHerald::Formatter
      include NagiosHerald::Logging

      # Public: Overrides Formatter::Base#additional_info.
      # Colorizes the service output to highlight either the iowait or idle value.
      #
      # WARNING CPU iowait is > 0%: user=3.60% system=0.99% iowait=0.00% idle=95.41%
      # CRITICAL CPU idle is < 100%: user=3.02% system=3.25% iowait=0.01% idle=93.72%
      #
      # Returns nothing. Updates the formatter content hash.
      def additional_info
        section = __method__
        output = get_nagios_var("NAGIOS_#{@state_type}OUTPUT")
        #if match = /(?<state>\w+ CPU) (?<metric>\w+) (?<threshold_and_stats>.*) (?<iowait>iowait=.*%) (?<idle>idle=.*%)/.match(output)
        add_html(section, "<b>Additional Info</b>:<br>")
        add_text(section, "Additional Info: ")
        if match = /(?<state>\w+ CPU) (?<metric>iowait) (?<threshold_and_stats>.*) (?<iowait>iowait=.*%) (?<idle>idle=.*%)/.match(output)
          iowait_info = "#{match[:state]} <b><font color='red'>#{match[:metric]}</font></b> "
          iowait_info += "#{match[:threshold_and_stats]} <b><font color='red'>#{match[:iowait]}</font></b> "
          iowait_info += "#{match[:idle]}"
          add_html(section, iowait_info)
        elsif match = /(?<state>\w+ CPU) (?<metric>idle) (?<threshold_and_stats>.*) (?<iowait>iowait=.*%) (?<idle>idle=.*%)/.match(output)
          iowait_info = "#{match[:state]} <b><font color='red'>#{match[:metric]}</font></b> "
          iowait_info += "#{match[:threshold_and_stats]} #{match[:iowait]} "
          iowait_info += "<b><font color='red'>#{match[:idle]}</font></b>"
          add_html(section, iowait_info)
        else
          add_html(section, output)
        end
        add_text(section, output)   # nothing fancy to see for text
      end

      # Public: Overrides Formatter::Base#additional_details.
      # Colorizes the `ps` output returned by the check_cpu_stats NRPE check.
      # The output contains the top n processes by CPU similar to:
      #
      # TOP 5 PROCESSES BY CPU:
      #  %CPU         TIME         USER    PID COMMAND
      #   6.0     00:00:00        larry  32256 ps -eo %cpu,cputime,user,pid,args --sort -%cpu
      #   0.7     06:22:09       nobody  12161 /usr/sbin/gmond
      #   0.6   1-02:14:24         root   1424 [kipmi0]
      #   0.5     00:49:52        10231  15079 mosh-server new -s -c 8 -l LANG=en_US.UTF-8
      #   0.3     04:36:53         root  12996 /opt/extrahop/sbin/rpcapd -v -d -L -f /opt/extrahop/etc/rpcapd.ini
      #
      # Returns nothing. Updates the formatter content hash.
      def additional_details
        section = __method__
        long_output = get_nagios_var("NAGIOS_LONG#{@state_type}OUTPUT")
        lines = long_output.split('\n')
        html = []
        html << "<pre>"
        html << lines[0]  # TOP 5 PROCESSES BY CPU:
        html << lines[1]  # %CPU         TIME         USER    PID COMMAND
        html << "<font color='red'>#{lines[2]}</font>"  # Color the first result red...
        for i in 3..lines.length-1
          html << "<font color='orange'>#{lines[i]}</font>" # ...and the remainder orange.
        end
        html << "</pre>"
        output_string = html.join( "<br>" )
        add_html(section, "<b>Additional Details</b>:")
        add_html(section, output_string)
        add_text(section, "Additional Details:\n#")
        add_text(section, "#{unescape_text(long_output)}\n")
        line_break(section)
      end

    end
  end
end
