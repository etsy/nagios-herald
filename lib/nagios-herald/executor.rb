require 'nagios-herald'
require 'choice'
require 'app_conf'

module NagiosHerald
  class Executor

    def parse_options
      program_name = File.basename($0)

      Choice.options do
        header "Nagios Herald - Spread the word"
        header ""

        option :configuration_manager do
          short "-C"
          long  "--configuration-manager"
          desc  "Configuration Management Tool"
          default "chef"
          desc  "Valid options: simple, chef"
        end

        option :config_file do
          short "-c"
          long  "--config-file"
          desc  "Specify an alternate location for the config file."
          default File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'etc', 'config.yml'))
        end

        option :debug do
          short "-d"
          long  "--debug"
          desc  "BE VERBOSE! B-E V-E-R-B-O-S-E!"
        end

        option :env do
          short "-e"
          long  "--env-file"
          desc  "Path to a file containing environment variables to use for testing/debugging (i.e. nagios_vars)."
        end

        option :formatter_dir do
          short   "-F"
          long    "--formatter-dir"
          desc    "Formatter directory"
          default nil
        end

        option :formatter_name do
          short   "-f"
          long    "--formatter"
          desc    "Formatter name"
          default nil
        end

        option :formatter_dir do
          short   "-F"
          long    "--formatter-dir"
          desc    "Formatter directory"
          default nil
        end

        option :message_type do
          short   "-m"
          long    "--message-type"
          desc    "Type of message to deliver (i.e. email, IRC, pager)"
          desc    "[DEFAULT] email"
          desc    "FUTURE USE"
          default "email"
        end

        option :nosend do
          short "-N"
          long  "--no-send"
          desc  "Output content to screen but do not send it"
        end

        option :notification_type do
          short "-n"
          long  "--notification-type"
          desc  "NAGIOS_NOTIFICATION_TYPE to report - defaults to the nagios env variable."
          desc  "Valid options: PROBLEM, FLAPPINGSTART, RECOVERY, FLAPPINGSTOP, ACKNOWLEDGEMENT"
        end

        option :pager_mode do
          short "-p"
          long  "--pager"
          desc  "Enable pager mode"
        end

        option :recipients do
          short "-r"
          long  "--recipient"
          desc  "A recipient's email address. Specify multiple recipients with multiple '-r' arguments."
          desc  "If not specified, recipients are looked up in the ENV['NAGIOS_CONTACTEMAIL'] environment variable."
        end

        option :trace do
          short "-t"
          long  "--trace"
          desc  "Show a full traceback on error"
          default false
        end

        option :nagiosurl do
          short "-u"
          long  "--nagios-cgi-url"
          desc  "Nagios CGI url (used for acknowledgement links)"
        end

        option :replyto, :required => true do
          short "-y"
          long  "--reply-to"
          desc  "[REQUIRED] Reply-to email address (i.e. nagios@example.com) used for acknowledgement replies."
        end

        footer ""
        footer "EXAMPLES"
        footer "--------"
        footer "#{program_name} -r ops@example.com --env-file=test/env_files/nagios_vars -y nagios@example.com --formatter=check_disk"
        footer ""
      end

      return Choice.choices

    end

    def load_env_from_file(path)
      File.readlines(path).each do |line|
        values = line.split("=")
        key = values[0]
        value = values[1, values.length - 1 ].map {|v| v.strip() }.join('=')
        ENV[key] = value
      end
    end

    def load_formatter(name, formatter_dir = nil)
      return if name.nil?
      formatter_dir = formatter_dir || File.join(File.dirname(__FILE__) , "formatters")
      formatter_path = File.expand_path(File.join(formatter_dir, name.downcase))
      begin
        require formatter_path
        formatter_class = "NagiosHerald::Formatter::#{Util::underscore_to_camel_case(name)}"
        Util::constantize(formatter_class)
      rescue LoadError
        puts "Exception encountered loading #{formatter_path}"
        return nil
      end
    end

    def get_formatter
      formatter_class = load_formatter(@options.formatter_name, @options.formatter_dir)
      if formatter_class.nil?
        puts "Exception encountered loading #{@options.formatter_name} - defaulting to default formatter"
        formatter_class = load_formatter("default_formatter")
      end
      return formatter_class
    end

    def get_config
      abort("Config file not found #{@options.config_file}") unless File.exists? @options.config_file
      config       = AppConf.new
      config.load( @options.config_file )
      return config
    end

    # TODO: combine this with 'report()' and rename to 'run()'
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
      load_env_from_file(@options.env) if @options.env

      # Load the config
      config = get_config

      # Get a configuration manager
      cfgmgr = ConfigurationManager.get_configuration_manager(@options.configuration_manager, config)

      # Get a formatter
      formatter_class = get_formatter
      formatter = formatter_class.new(cfgmgr, @options)

      contact_email = @options.recipients.nil? ? ENV['NAGIOS_CONTACTEMAIL'] : @options.recipients
      contact_pager = @options.pager_mode ? @options.recipients : ENV['NAGIOS_CONTACTPAGER']
      nagios_notification_type = @options.notification_type.nil? ? ENV["NAGIOS_NOTIFICATIONTYPE"] : @options.notification_type

      # Report for email and pager
      # we eventually want to determine the correct class based on the requested message type (--message-type)
      [contact_email, contact_pager].each do | contact |
        next if contact.nil? || contact.eql?("")
        message = Message::Email.new(formatter, contact, @options)
        formatters = Message::Formatter.new # a null context? simply loads all formatters for us
        # can formatters stay namespaced at the same level of Message (i.e. nagios-heralf/formatters)?
        formatter_instance = Message::Formatter.formatters['foo']
        foo_formatter = formatter_instance.new
        message.generate(nagios_notification_type)
        message.send
      end
    end

  end
end
