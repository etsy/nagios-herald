require 'nagios-herald'
require 'choice'
require 'app_conf'

module NagiosHerald
  module Exec
    class NagiosHerald

      def get_formatter_or_default
        formatter_class = Util::load_formatter(@options.formatter_name, @options.formatter_dir)
        if formatter_class.nil?
          puts "Exception encountered loading #{@options.formatter_name} - defaulting to default formatter"
          formatter_class = Util::load_formatter("default_formatter")
        end
        return formatter_class
      end

      def get_config
        abort("Config file not found #{@options.config_file}") unless File.exists? @options.config_file
        config       = AppConf.new
        config.load( @options.config_file )
        return config
      end

      def report!
        begin
          @options = parse_options
        rescue SystemExit
          $stderr.puts "Invalid  or missing options\n"
          exit 1
        end

        begin
          report
        rescue Exception => e
          raise e if @options[:trace] || e.is_a?(SystemExit)

          $stderr.print "#{e.class}: " unless e.class == RuntimeError
          $stderr.puts "#{e.message}"
          $stderr.puts "  Use --trace for backtrace."
          exit 1
        end
        exit 0
      end


      def report
        # Load the environment if asked for it
        Util::load_env_from_file(@options.env) if @options.env

        # Load the config
        config = get_config

        # Get a configuration manager
        cfgmgr = ConfigurationManager.get_configuration_manager(@options.configuration_manager, config)

        # Get a formatter
        formatter_class = get_formatter_or_default
        formatter = formatter_class.new(cfgmgr, @options)

        # Get an alert handler for our formatter
        handler = Engine.new(formatter, @options)

        contact_email = @options.recipients.nil? ? ENV['NAGIOS_CONTACTEMAIL'] : @options.recipients
        contact_pager = @options.pager_mode ? @options.recipients : ENV['NAGIOS_CONTACTPAGER']
        notification_type = @options.notification_type.nil? ? ENV["NAGIOS_NOTIFICATIONTYPE"] : @options.notification_type

        # Report for email and pager
        [contact_email, contact_pager].each do | contact |
          next if contact.nil? || contact.eql?("")
          message = EmailMessage.new(contact, @options)
          handler.report(message, notification_type)
        end
      end

      def parse_options
        program_name = File.basename($0)

        Choice.options do
          header "Nagios handler"
          header ""

          option :config_file do
            short "-c"
            long  "--config-file"
            desc  "Specify an alternate location for the config file."
            default File.expand_path(File.dirname(__FILE__)  + "/../../etc/config.yml")
          end

          option :debug do
            short "-d"
            long  "--debug"
            desc  "BE VERBOSE! B-E V-E-R-B-O-S-E!"
          end

          option :env do
            short "-e"
            long  "--env-file"
            desc  "Path to a file containing environment variables to use for testind/debugging (i.e. nagios_vars)."
          end

          option :formatter_name do
            short   "-f"
            long    "--formatter"
            desc    "Formatter name"
            default nil
          end

          option :formatter_dir do
            long    "--formatter-dir"
            desc    "Formatter directory"
            default nil
          end

          option :notification_type do
            short "-n"
            long  "--notification_type"
            desc  "NAGIOS_NOTIFICATION_TYPE to report - defaults to the nagios env variable."
            desc  "Valid options: PROBLEM, FLAPPINGSTART, RECOVERY, FLAPPINGSTOP, ACKNOWLEDGEMENT"
          end

          option :recipients do
            short "-r"
            long  "--recipient"
            desc  "A recipient's email address. Specify multiple recipients with multiple '-r' arguments."
            desc  "If not specified, recipients are looked up in the ENV['NAGIOS_CONTACTEMAIL'] environment variable."
          end

          option :pager_mode do
            short "-p"
            long  "--pager"
            desc  "Enable pager mode"
          end

          option :nagiosurl do
            short "-u"
            long  "--nagios-cgi-url"
            desc  "Nagios CGI url (used for acknowledgement links)"
          end

          option :replyto, :required => true do
            short "-y"
            long  "--reply-to"
            desc  "[REQUIRED] Reply-to email address (i.e. nagios@etsy.com) used for acknowledgement replies."
          end

          option :noemail do
            long  "--no-email"
            desc  "Output email content to screen but do not send it."
          end

          option :configuration_manager do
            long  "--configuration-manager"
            desc  "Configuration Management Tool"
            default "chef"
            desc  "Valid options: simple, chef"
          end

          option :trace do
            long  "--trace"
            desc  "Show a full traceback on error"
            default false
          end

          footer ""
          footer "EXAMPLES"
          footer "--------"
          footer "#{program_name} -r rfrantz@etsy.com --env-file=tests/env_files/nagios_vars -y nagios@etsy.com --formatter=check_disk"
          footer ""
        end

        return Choice.choices
      end
    end
  end
end
