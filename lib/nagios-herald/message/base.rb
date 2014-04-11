require 'app_conf'
require 'tmpdir'
require 'nagios-herald/logging'
require 'nagios-herald/util'
require 'nagios-herald/formatter_loader'
require 'ap'

module NagiosHerald
  class Message
    include NagiosHerald::Logging
    include NagiosHerald::Util

    def initialize(notification_formatter, options)
      @formatter  = notification_formatter
      @nosend   = options.nosend
      @pager_mode = options.pager_mode
      @sandbox    = nil
      formatter_loader = NagiosHerald::FormatterLoader.new
      formatter_files = formatter_loader.load_formatters
    end

    def self.formatters
      @@formatters ||= {}
    end

    def self.inherited(subclass)
      puts "#{subclass} inherited from #{self.name}!"
      subclass_base_name = subclass.name.split('::').last
      puts "subclass base name: #{subclass_base_name}"
      subclass_base_name.gsub!(/[A-Z]/) { |s| "_" + s } # replace uppercase with underscore and lowercase
      subclass_base_name.downcase!
      subclass_base_name.sub!(/^_/, "")
      puts "snake_case: #{subclass_base_name}"
      formatters[subclass_base_name] = subclass
      ap formatters
    end

    def generate_section(name, *section_style_args)
      if @formatter.respond_to?(name)
        #logger.debug("Generating section #{name}")
        @formatter.start_section(*section_style_args)
        @formatter.send(name)
        @formatter.end_section
      else
        logger.error("Formatter method not found! #{name}")
      end
    end

    def generate_problem_content
      if @pager_mode
        generate_section("format_short_state_detail")
        @formatter.tag = ""
      else
        @formatter.tag = "ALERT"
        generate_section("format_host_info")
        generate_section("format_state_info")
        generate_section("format_additional_info")
        generate_section("format_action_url")
        generate_section("format_state_detail") # format_notes and format_additional_details for services
        generate_section("format_recipients_email_link")
        generate_section("format_notification_info")
        generate_section("format_alert_ack_url")
      end
    end

    def generate_recovery_content
      @formatter.tag = "OK"
      if @pager_mode
        generate_section("format_short_state_detail")
      else
        generate_section("format_host_info", "color:green")
        generate_section("format_state_info", "color:green")
        generate_section("format_additional_info", "color:green")
        generate_section("format_action_url", "color:green")
        generate_section("format_state_detail", "color:green") # format_notes and format_additional_details for services
        generate_section("format_recipients_email_link")
        generate_section("format_notification_info")
      end
    end

    def generate_ack_content
      @formatter.tag = "ACK"
      if @pager_mode
        generate_section("format_short_ack_info")
      else
        generate_section("format_host_info")
        generate_section("format_ack_info")
      end
    end

    def generate_content(nagios_notification_type)
      case nagios_notification_type
        when "PROBLEM", "FLAPPINGSTART"
          generate_problem_content
        when "RECOVERY", "FLAPPINGSTOP"
          generate_recovery_content
        when "ACKNOWLEDGEMENT"
          generate_ack_content
        else
          $stderr.puts "Invalid Nagios notification type!\nExpecting something like PROBLEM or RECOVERY"
          exit 1
        end
    end

    def get_sandbox_path
      @sandbox = Dir.mktmpdir if @sandbox.nil?
      return @sandbox
    end

    def clean_sandbox
      FileUtils.remove_entry @sandbox if  File.directory?(@sandbox)
    end

    def generate(nagios_notification_type)
      @formatter.email = self
      @formatter.sandbox = get_sandbox_path

      generate_content(nagios_notification_type)
      generate_subject
    end

    def generate_subject
      raise Exception, "#{self.to_s}: You must override generate_subject()"
    end

    def send
      raise Exception, "#{self.to_s}: You must override send()"
    end

  end
end
