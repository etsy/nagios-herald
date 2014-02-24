#!/usr/bin/env ruby

require 'tmpdir'

module NagiosHerald
  module Formatter
    class DefaultFormatter

      attr_accessor :tag
      attr_accessor :email
      attr_accessor :sandbox

      def initialize(cfgmgr, options)
        @cfgmgr     = cfgmgr
        @nagios_url = options.nagiosurl
        @state_type = get_nagios_var("NAGIOS_SERVICESTATE") != "" ? "SERVICE" : "HOST"
        @tag        = ""
        @email      = nil
      end

      def add_text(bit)
        @email.add_text(bit) if @email
      end

      def add_html(bit)
        @email.add_html(bit) if @email
      end

      def add_attachment(path)
        @email.add_attachment(path) if @email
      end

      def format_line_break
        add_text "\n"
        add_html "<br>"
      end

      def start_section(*section_style_args)
        if ! section_style_args.nil?
           style = section_style_args.join(';')
           add_html "<div style='#{style}'>"
        end
      end

      def end_section
        add_html "</div>"
      end

      def get_default_value(name)
        return nil
      end

      def get_nagios_var(name)
        value = ENV[name]
        if value.nil?
          return get_default_value(name)
        end
        return value
      end

      ## individual sections formatter

      def format_subject
        hostname      = get_nagios_var("NAGIOS_HOSTNAME")
        service_desc    = get_nagios_var("NAGIOS_SERVICEDESC")
        notification_type = get_nagios_var("NAGIOS_NOTIFICATIONTYPE")
        state       = get_nagios_var("NAGIOS_#{@state_type}STATE")

        subject="#{@tag}: #{hostname}"
        subject += "/#{service_desc}" if service_desc != ""

        if @state_type == "SERVICE"
          if @pager_mode
            subject="SVC #{subject}: #{@state_type}"
          else
            subject="** #{notification_type} Service #{subject} is #{state} **"
          end
        else
          if @pager_mode
            subject="HST #{subject}: ${@state_type}"
          else
            subject="** #{notification_type} Host #{subject} is #{state} **"
          end
        end
        @email.subject = subject
      end

      def format_host_info
        notification_type = get_nagios_var("NAGIOS_NOTIFICATIONTYPE")
        hostname      = get_nagios_var("NAGIOS_HOSTNAME")
        service_desc    = get_nagios_var("NAGIOS_SERVICEDESC")
        add_text "Host: #{hostname} "
        add_html "<br><b>Host</b>: #{hostname} "
        if !service_desc.nil? and !service_desc.empty?
          add_text "Service: #{service_desc}\n"
          add_html "<b>Service</b>: #{service_desc}<br/>"
        else
          # we need a trailing newline if no service description
          format_line_break
        end
        format_line_break
      end

      def format_state_info
        state     = get_nagios_var("NAGIOS_#{@state_type}STATE")
        duration    = get_nagios_var("NAGIOS_#{@state_type}DURATION")
        last_duration = get_nagios_var("NAGIOS_LAST#{@state_type}STATE")
        attempts    = get_nagios_var("NAGIOS_#{@state_type}ATTEMPT")
        max_attempts  = get_nagios_var("NAGIOS_MAX#{@state_type}ATTEMPTS")
        add_text "State is now: #{state} for #{duration} (was #{last_duration}) after #{attempts} / #{max_attempts} checks\n"
        if state.eql? 'OK' or state.eql? 'UP'
            add_html "State is now: <b>#{state}</b> for <b>#{duration}</b> (was #{last_duration}) after <b>#{attempts} / #{max_attempts}</b> checks<br/>"
        else
            add_html "State is now: <b><font style='color:red'>#{state}</font></b> for <b>#{duration}</b> (was #{last_duration}) after <b>#{attempts} / #{max_attempts}</b> checks<br/>"
        end
        format_line_break
      end

      def format_notification_info
        date    = get_nagios_var("NAGIOS_LONGDATETIME")
        number    = get_nagios_var("NAGIOS_NOTIFICATIONNUMBER")
        add_text "Notification sent at: #{date} (notification number #{number})\n\n"
        add_html "Notification sent at: #{date} (notification number #{number})<br><br>"
      end

      # checks plugin's output
      def format_additional_info
        output    = get_nagios_var("NAGIOS_#{@state_type}OUTPUT")
        if !output.nil? and !output.empty?
          add_text "Additional info: #{NagiosHerald::Util::unescape_text(output)}\n\n"
          add_html "<b>Additional info</b>: #{output}<br><br>"
        end
      end

      def format_notes
        notes = get_nagios_var("NAGIOS_#{@state_type}NOTES")
        if !notes.nil? and !notes.empty?
          add_text "Notes: #{NagiosHerald::Util::unescape_text(notes)}\n\n"
          add_html "<b>Notes</b>: #{notes}<br><br>"
        end

        notes_url = get_nagios_var("NAGIOS_#{@state_type}NOTESURL")
        if !notes_url.nil? and !notes_url.empty?
          add_text "Notes URL: #{notes_url}\n\n"
          add_html "<b>Notes URL</b>: #{notes_url}<br><br>"
        end
      end

      # checks plugin's long output
      def format_additional_details
        long_output   = get_nagios_var("NAGIOS_LONG#{@state_type}OUTPUT")
        if !long_output.nil? and !long_output.empty?
          add_text "Additional Details: #{NagiosHerald::Util::unescape_text(long_output)}\n"
          add_html "<b>Additional Details</b>: <pre>#{NagiosHerald::Util::unescape_text(long_output)}</pre><br><br>"
        end
      end

      def format_action_url
        action_url = get_nagios_var("NAGIOS_#{@state_type}ACTIONURL")
        if !action_url.nil? and !action_url.empty?
          add_text "Action URL: #{action_url}\n\n"
          add_html "<b>Action URL</b>: #{action_url}<br><br>"
        end
      end

      def format_state_detail
        format_additional_info
        format_action_url
        if @state_type == "SERVICE"
          format_notes
          format_additional_details
        end
        format_line_break
      end

      def format_short_state_detail
        output   = get_nagios_var("NAGIOS_#{@state_type}OUTPUT")
        add_text = "#{output}\n"
        add_html = "#{output}<br>"
      end

      def format_recipients_email_link
        hostname      = get_nagios_var("NAGIOS_HOSTNAME")
        if @state_type == "SERVICE"
          service_desc  = get_nagios_var("NAGIOS_SERVICEDESC")
          subject = "#{hostname} - #{service_desc}"
        else
          subject = "#{hostname}"
        end

        recipients      = get_nagios_var("NAGIOS_NOTIFICATIONRECIPIENTS")
        return if recipients.nil?
        recipients_list   = recipients.split(',')
        recipients_mail   = recipients_list.map {|n| n + "@etsy.com"}
        recipients_mail_str = recipients_mail.join(',')
        add_text "Sent to #{recipients}\n"
        add_html "Sent to <a href=\"mailto:#{recipients_mail_str}?subject=#{subject}\">#{recipients}</a><br>"
      end

      def format_ack_info
        date    = get_nagios_var("NAGIOS_LONGDATETIME")
        author    = get_nagios_var("NAGIOS_#{@state_type}ACKAUTHOR")
        comment   = get_nagios_var("NAGIOS_#{@state_type}ACKCOMMENT")
        hostname  = get_nagios_var("NAGIOS_HOSTNAME")

        add_text "At #{date} #{author}"
        add_html "At #{date} #{author}"

        if @state_type == "SERVICE"
          desc = get_nagios_var("NAGIOS_SERVICEDESC")
          add_text " acknowledged #{desc} on #{hostname}.\n\n"
          add_html " acknowledged #{desc} on #{hostname}.<br><br>"
        else
          add_text " acknowledged #{hostname}.\n\n"
          add_html " acknowledged #{hostname}.<br><br>"

        end
        add_text "Comment: #{comment}" if comment
        add_html "Comment: #{comment}" if comment
      end

      def format_short_ack_info
        author    = get_nagios_var("NAGIOS_#{@state_type}ACKAUTHOR")
        comment   = get_nagios_var("NAGIOS_#{@state_type}COMMENT")
        hostname  = get_nagios_var("NAGIOS_HOSTNAME")

        add_text "#{author}  ack'd "
        add_html "#{author}  ack'd "

        if @state_type == "SERVICE"
          desc = get_nagios_var("NAGIOS_SERVICEDESC")
          add_text "#{desc} on #{hostname}.\n"
          add_html "#{desc} on #{hostname}.<br>"
        else
          add_text "#{hostname}.\n"
          add_html "#{hostname}.<br>"

        end
        add_text "Comment: #{comment}" if comment
        add_html "Comment: #{comment}" if comment
      end

      def format_alert_ack_url
        hostname  = get_nagios_var("NAGIOS_HOSTNAME")
        service_desc = get_nagios_var("NAGIOS_SERVICEDESC")

        if service_desc != ""
          url = "#{@nagios_url}?cmd_typ=34&host=#{hostname}&service=#{service_desc}"
        else
          url = "#{@nagios_url}?cmd_typ=33&host=#{hostname}"
        end
        url = URI.escape(url)
        add_text "Acknowledge this alert: #{url}\n"
        add_html "Acknowledge this alert: #{url}<br>"
      end
    end
  end
end
