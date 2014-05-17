module NagiosHerald
  class Formatter
    class CheckMemory < NagiosHerald::Formatter
      include NagiosHerald::Logging

      # Public: Overrides Formatter::Base#additional_details.
      # Colorizes the `ps` output returned by the check_mem NRPE check.
      # The output contains the top n processes by memory utilization similar to:
      #
      # TOP 5 PROCESSES BY MEMORY USAGE:
      #  %MEM          RSS         USER    PID COMMAND
      #   2.4      1231696        larry   6658 tmux
      #   1.5       777204          moe  32234 tmux/tmux -CC
      #   0.8       399964        curly  12161 /usr/sbin/gmond
      #   0.7       384772         shep   1945 /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib64/mysql/plugin --user=mysql --log-error=/var/lib/mysql/mysql.example.com.err --pid-file=/var/lib/mysql/mysql.example.com.pid
      #   0.7       355148         root   1245 SCREEN
      #
      # Returns nothing. Updates the formatter content hash.
      def additional_details
        section = __method__
        long_output = get_nagios_var("NAGIOS_LONG#{@state_type}OUTPUT")
        lines = long_output.split('\n')
        html = []
        html << "<pre>"
        html << lines[0]  # TOP 5 PROCESSES BY MEMORY USAGE:
        html << lines[1]  # %MEM          RSS         USER    PID COMMAND
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
