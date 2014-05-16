# Formatter objects know best about how to create and format content.
# The Base class defines several variables and methods that can be used in subclasses.
# Nearly all of them can be overridden. Subclasses can also extend functionality and
# call on helpers.

# Dear Reader,
# There is a brittle, un-OOP pattern in this class, but it gets the job done
# because sometimes "working" is better than "elegant" or "correct".
# Your exercise, should you choose to take it on, is to devise a better way
# for a formatter to know which content to generate based on the message type.
# THIS IS ESPECIALLY IMPORTANT FOR SUBCLASSES THAT OVERRIDE METHODS!
# Hit me with your best shot.

require 'tmpdir'
require 'nagios-herald/logging'
require 'nagios-herald/util'
require 'nagios-herald/formatter_loader'

module NagiosHerald
  class Formatter
    include NagiosHerald::Logging
    include NagiosHerald::Util

    attr_accessor :content  # all the content required to generate a message
    attr_accessor :sandbox # @sandbox is the place to save attachments, possibly a tempdir
    attr_accessor :state_type

    def initialize(options)
      @content = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) } # autovivify
      @content[:attachments] = []
      @content[:html]
      @content[:subject] = ""
      @content[:text]
      @nagios_url = options[:nagios_url]
      @sandbox  = get_sandbox_path
      @state_type = get_nagios_var("NAGIOS_SERVICESTATE") != "" ? "SERVICE" : "HOST"

    end

    def self.formatters
      @@formatters ||= {}
    end

    # Public: When subclassed formatters are instantiated, add them to the @@formatters hash.
    # The key is the downcased and snake_cased name of the class file (i.e. check_disk);
    # the value is the actual class (i.e. CheckDisk) so that we can easily
    # instantiate formatters when we know the formatter name.
    # Learned this pattern thanks to the folks at Chef and @jonlives.
    # See https://github.com/opscode/chef/blob/11-stable/lib/chef/knife.rb#L79#L83
    #
    # Returns the formatters hash.
    def self.inherited(subclass)
      subclass_base_name = subclass.name.split('::').last
      subclass_base_name.gsub!(/[A-Z]/) { |s| "_" + s } # replace uppercase with underscore and lowercase
      subclass_base_name.downcase!
      subclass_base_name.sub!(/^_/, "")   # strip the leading underscore
      formatters[subclass_base_name] = subclass
    end

    # Public: Concatenates text content.
    #
    # section - The content section name whose text we'll concatenate
    # text - The text we want to concatenate
    #
    # Example:
    #
    #   add_text("state_detail", "Service is somewhere in Kansas")
    #
    # Returns the concatenated HTML for the given section.
    def add_text(section, text)
      # Ensure our key is a symbol, regardless if we're passed a string or symbol
      section = section.to_sym
      if @content[:text][section].nil? or @content[:text][section].empty?
        @content[:text][section] = text
      else
        @content[:text][section] += text
      end
    end

    # Public: Concatenates HTML content.
    #
    # section - The content section name whose HTML we'll concatenate
    # text - The HTML we want to concatenate
    #
    # Example:
    #
    #   add_html("state_detail", "Service is somewhere in Kansas")
    #
    # Returns the concatenated HTML for the given section.
    def add_html(section, html)
      # Ensure our key is a symbol, regardless if we're passed a string or symbol
      section = section.to_sym
      if @content[:html][section].nil? or @content[:html][section].empty?
        @content[:html][section] = html
      else
        @content[:html][section] += html
      end
    end

    # Public: Add an attachment's path to an array.
    #
    # path - The fully qualified path for a file attachment
    #
    # Example:
    #
    #   add_attachment("/tmp/file-to-attach.txt")
    #
    # Returns the array of attachment paths.
    def add_attachment(path)
      #@attachments << path
      @content[:attachments] << path
    end

    #
    # format the content
    #

    # Public: Appends a newline in text and HTML format.
    #
    # section - The content section name that needs the line break
    #
    # Example
    #
    #   line_break(additional_info)
    #
    # Appends text and HTML output to the appropriate sections in @content
    def line_break(section)
      add_text(section, "\n")
      add_html(section, "<br>")
    end

    # Public: Formats the information about the host that's being alerted on.
    # Generates text and HTML output.
    def host_info
      section = __method__
      text = ""
      html = ""
      notification_type = get_nagios_var("NAGIOS_NOTIFICATIONTYPE")
      hostname          = get_nagios_var("NAGIOS_HOSTNAME")
      service_desc      = get_nagios_var("NAGIOS_SERVICEDESC")
      text += "Host: #{hostname} "
      html += "<br><b>Host</b>: #{hostname} "
      if !service_desc.nil? and !service_desc.empty?
        text += "Service: #{service_desc}\n"
        html += "<b>Service</b>: #{service_desc}<br/>"
      else
        # we need a trailing newline if no service description
        line_break(section)
      end
      add_text(section, text)
      add_html(section, html)
      line_break(section)
    end

    # Public: Formats information about the state of the thing being alerted on
    # where 'thing' is either HOST or SERVICE.
    # Generates text and HTML output.
    def state_info
      section = __method__
      text = ""
      html = ""
      state         = get_nagios_var("NAGIOS_#{@state_type}STATE")
      duration      = get_nagios_var("NAGIOS_#{@state_type}DURATION")
      last_duration = get_nagios_var("NAGIOS_LAST#{@state_type}STATE")
      attempts      = get_nagios_var("NAGIOS_#{@state_type}ATTEMPT")
      max_attempts  = get_nagios_var("NAGIOS_MAX#{@state_type}ATTEMPTS")

      text += "State is now: #{state} for #{duration} (was #{last_duration}) after #{attempts} / #{max_attempts} checks\n"

      if state.eql? 'OK' or state.eql? 'UP'
          html += "State is now: <b>#{state}</b> for <b>#{duration}</b> (was #{last_duration}) after <b>#{attempts} / #{max_attempts}</b> checks<br/>"
      else
          html += "State is now: <b><font style='color:red'>#{state}</font></b> for <b>#{duration}</b> (was #{last_duration}) after <b>#{attempts} / #{max_attempts}</b> checks<br/>"
      end
      add_text(section, text)
      add_html(section, html)
      line_break(section)
    end

    # Public: Formats information about the notification.
    # Provides information such as the date and notification number.
    # Generates text and HTML output.
    def notification_info
      section = __method__
      text = ""
      html = ""
      date   = get_nagios_var("NAGIOS_LONGDATETIME")
      number = get_nagios_var("NAGIOS_NOTIFICATIONNUMBER")
      text += "Notification sent at: #{date} (notification number #{number})\n\n"
      html += "Notification sent at: #{date} (notification number #{number})<br><br>"
      add_text(section, text)
      add_html(section, html)
    end

    # Public: Formats information provided plugin's output.
    # Generates text and HTML output.
    def additional_info
      section = __method__
      text = ""
      html = ""
      output = get_nagios_var("NAGIOS_#{@state_type}OUTPUT")
      if !output.nil? and !output.empty?
        text += "Additional Info: #{unescape_text(output)}\n\n"
        html += "<b>Additional Info</b>: #{output}<br><br>"
        add_text(section, text)
        add_html(section, html)
      end
    end

    # Public: Formats information provided plugin's *long* output.
    # Generates text and HTML output.
    def additional_details
      section = __method__
      text = ""
      html = ""
      long_output = get_nagios_var("NAGIOS_LONG#{@state_type}OUTPUT")
      if !long_output.nil? and !long_output.empty?
        text += "Additional Details: #{unescape_text(long_output)}\n"
        html += "<b>Additional Details</b>: <pre>#{unescape_text(long_output)}</pre><br><br>"
        add_text(section, text)
        add_html(section, html)
      end
    end

    # Public: Formats the notes information for this alert.
    # Generates text and HTML output.
    def notes
      section = __method__
      text = ""
      html = ""
      notes = get_nagios_var("NAGIOS_#{@state_type}NOTES")
      if !notes.nil? and !notes.empty?
        text += "Notes: #{unescape_text(notes)}\n\n"
        html += "<b>Notes</b>: #{notes}<br><br>"
      end

      notes_url = get_nagios_var("NAGIOS_#{@state_type}NOTESURL")
      if !notes_url.nil? and !notes_url.empty?
        text += "Notes URL: #{notes_url}\n\n"
        html += "<b>Notes URL</b>: #{notes_url}<br><br>"
      end
      add_text(section, text)
      add_html(section, html)
    end

    # Public: Formats the action URL for this alert.
    # Generates text and HTML output.
    def action_url
      section = __method__
      text = ""
      html = ""
      action_url = get_nagios_var("NAGIOS_#{@state_type}ACTIONURL")
      if !action_url.nil? and !action_url.empty?
        text += "Action URL: #{action_url}\n\n"
        html += "<b>Action URL</b>: #{action_url}<br><br>"
      end
      add_text(section, text)
      add_html(section, html)
    end

    # FIXME: Looks like a dupe of #additional_info (used in pager alerts, it seems)
    def short_state_detail
      section = __method__
      text = ""
      html = ""
      output   = get_nagios_var("NAGIOS_#{@state_type}OUTPUT")
      text += "#{output}\n"
      html += "#{output}<br>"
      add_text(section, text)
      add_html(section, html)
    end

    # Public: Formats the email recipients and URIs
    # Generates text and HTML output.
    def recipients_email_link
      section = __method__
      text = ""
      html = ""
      recipients = get_nagios_var("NAGIOS_NOTIFICATIONRECIPIENTS")
      return if recipients.nil?
      recipients_list = recipients.split(',')
      text += "Sent to #{recipients}\n"
      html += "Sent to #{recipients}<br>"
      add_text(section, text)
      add_html(section, html)
    end

    # Public: Formats the information about who ack'd the alert and when
    # Generates text and HTML output.
    def ack_info
      section = __method__
      text = ""
      html = ""
      date = get_nagios_var("NAGIOS_LONGDATETIME")
      author = get_nagios_var("NAGIOS_#{@state_type}ACKAUTHOR")
      comment = get_nagios_var("NAGIOS_#{@state_type}ACKCOMMENT")
      hostname = get_nagios_var("NAGIOS_HOSTNAME")

      text += "At #{date} #{author}"
      html += "At #{date} #{author}"

      if @state_type == "SERVICE"
        desc = get_nagios_var("NAGIOS_SERVICEDESC")
        text += " acknowledged #{desc} on #{hostname}.\n\n"
        html += " acknowledged #{desc} on #{hostname}.<br><br>"
      else
        text += " acknowledged #{hostname}.\n\n"
        html += " acknowledged #{hostname}.<br><br>"

      end
      text += "Comment: #{comment}" if comment
      html += "Comment: #{comment}" if comment
      add_text(section, text)
      add_html(section, html)
    end

    # Public: Formats brief ack information.
    # Useful for pager messages.
    # Generates text and HTML output.
    def short_ack_info
      section = __method__
      text = ""
      html = ""
      author    = get_nagios_var("NAGIOS_#{@state_type}ACKAUTHOR")
      comment   = get_nagios_var("NAGIOS_#{@state_type}COMMENT")
      hostname  = get_nagios_var("NAGIOS_HOSTNAME")

      text += "#{author}  ack'd "
      html += "#{author}  ack'd "

      if @state_type == "SERVICE"
        desc = get_nagios_var("NAGIOS_SERVICEDESC")
        text += "#{desc} on #{hostname}.\n"
        html += "#{desc} on #{hostname}.<br>"
      else
        text += "#{hostname}.\n"
        html += "#{hostname}.<br>"

      end
      text += "Comment: #{comment}" if comment
      html += "Comment: #{comment}" if comment
      add_text(section, text)
      add_html(section, html)
    end

    # Public: Formats the URI one can click to acknowledge an alert (i.e. in an email)
    # Generates text and HTML output.
    def alert_ack_url
      section = __method__
      text = ""
      html = ""
      hostname  = get_nagios_var("NAGIOS_HOSTNAME")
      service_desc = get_nagios_var("NAGIOS_SERVICEDESC")

      if service_desc != ""
        url = "#{@nagios_url}/nagios/cgi-bin/cmd.cgi?cmd_typ=34&host=#{hostname}&service=#{service_desc}"
      else
        url = "#{@nagios_url}/nagios/cgi-bin/cmd.cgi?cmd_typ=33&host=#{hostname}"
      end
      url = URI.escape(url)
      text += "Acknowledge this alert: #{url}\n"
      text += "Alternatively, reply to this message with the word 'ack' in the body to acknowledge the alert.\n"
      html += "Acknowledge this alert: #{url}<br>"
      html += "Alternatively, <b>reply</b> to this message with the word '<b><font color='green'>ack</font></b>' in the body to acknowledge the alert.<br>"
      add_text(section, text)
      add_html(section, html)
    end

    #
    # structural bits and content generation
    #

    # Public: Starts a format section's HTML <div> block.
    #
    # section - The name of the section whose HTML we'll start.
    # *section_style_args - CSS-type attributes used to style the content.
    #
    # Example
    #
    #   start_section("additional_details", "color:green")
    #
    # Generates HTML <div> block with the requested style.
    def start_section(section, *section_style_args)
      html = ""
      if !section_style_args.nil?
        style = section_style_args.join(';')
        html += "<div style='#{style}'>"
      else
        html += "<div>"
      end
      add_html(section, html)
    end

    # Public: Ends a format section's HTML <div> block.
    #
    # section - The name of the section whose HTML we'll start.
    #
    # Example
    #
    #   start_section("additional_details")
    #
    # Generates an ending HTML <div> tag.
    def end_section(section)
      add_html(section, "</div>")
    end

    # Public: Wrapper for starting a format section, calling the format method,
    # and ending the section.
    #
    # section - The name of the section whose HTML we'll start.
    # *section_style_args - A list of style attributes to be used in the <div> block for the section.
    #
    # Example:
    #
    #   generate_section("additional_info", "color:green", "font-weight:bold") - Color all text green and bold it
    #   generate_section("additional_info") - Color all text green
    #
    # Calls the relevant section method to generate content.
    def generate_section(section, *section_style_args)
      start_section(section, *section_style_args)
      self.send(section)
      end_section(section)
    end

    # Public: Generate content for PROBLEM alerts.
    def generate_problem_content
      generate_section("host_info")
      generate_section("state_info")
      generate_section("additional_info")
      generate_section("action_url")
      generate_section("notes")
      generate_section("additional_details")
      generate_section("recipients_email_link")
      generate_section("notification_info")
      generate_section("alert_ack_url")
    end

    # Public: Generate content for RECOVERY alerts.
    def generate_recovery_content
      generate_section("host_info")
      generate_section("state_info", "color:green")
      generate_section("additional_info")
      generate_section("action_url")
      generate_section("notes")
      generate_section("additional_details")
      generate_section("recipients_email_link")
      generate_section("notification_info")
    end

    # Public: Generate content for ACKNOWLEGEMENT alerts
    def generate_ack_content
      generate_section("host_info")
      generate_section("ack_info")
    end

    # Public: Dispatch method to help generate content based on notification
    # type.
    #
    # nagios_notification_type - One of any valid Nagios notification types.
    #
    # Example
    #
    #   generate_content("PROBLEM")
    #
    def generate_content(nagios_notification_type)
      case nagios_notification_type
        when "PROBLEM", "FLAPPINGSTART"
          generate_problem_content
        when "RECOVERY", "FLAPPINGSTOP"
          generate_recovery_content
        when "ACKNOWLEDGEMENT"
          generate_ack_content
        else
          logger.fatal "Invalid Nagios notification type! Expecting something like PROBLEM or RECOVERY."
          exit 1
        end
    end

    # Public: Generates a subject.
    #
    # Returns a subject.
    def generate_subject
      hostname          = get_nagios_var("NAGIOS_HOSTNAME")
      service_desc      = get_nagios_var("NAGIOS_SERVICEDESC")
      notification_type = get_nagios_var("NAGIOS_NOTIFICATIONTYPE")
      state             = get_nagios_var("NAGIOS_#{@state_type}STATE")

      subject="#{hostname}"
      subject += "/#{service_desc}" if service_desc != ""

      if @state_type == "SERVICE"
        subject="#{notification_type} Service #{subject} is #{state}"
      else
        subject="#{notification_type} Host #{subject} is #{state}"
      end
      @content[:subject] = subject
    end

    # Public: Generates content body.
    #
    # Call various formatting methods that each generate content for their given sections.
    def generate_message_content
        generate_subject
        nagios_notification_type = get_nagios_var('NAGIOS_NOTIFICATIONTYPE')
        generate_content(nagios_notification_type)
    end

    # Public: Creates a temporary directory in which to create files used in
    # attachments.
    #
    # Returns the path to a temporary directory.
    def get_sandbox_path
      @sandbox = Dir.mktmpdir if @sandbox.nil?
      return @sandbox
    end

    # Public: Does some housecleaning on the sandbox, if it exists.
    def clean_sandbox
      FileUtils.remove_entry @sandbox if File.directory?(@sandbox)
    end

  end
end

