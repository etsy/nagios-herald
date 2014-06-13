require 'nagios-herald'
require 'choice'
require 'app_conf'

module NagiosHerald
  class Executor
    include NagiosHerald::Logging
    include NagiosHerald::Util

    # Public: Parse the command line options.
    #
    # Returns a hash of the specified options and defaults as appropriate.
    def parse_options
      program_name = File.basename($0)

      Choice.options do
        header "Nagios Herald - Spread the word"
        header ""

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

        option :logfile do
          short   "-l"
          long    "--logfile"
          desc    "Logfile location"
          desc    "Can be a file name or STDOUT (i.e. -l /tmp/output.log or -l STDOUT)"
          desc    "[DEFAULT] Uses the value of 'logfile' in the config or STDOUT if not defined."
          default nil
        end

        option :message_type, :required => true do
          short   "-m"
          long    "--message-type"
          desc    "[REQUIRED] Type of message to deliver (i.e. email, IRC, pager)"
        end

        option :no_send do
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

        option :nagios_url do
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

    # Public: Load environment variables from a file.
    # This is useful for running controlled tests.
    #
    # Updates the ENV hash for each key/value pair.
    def load_env_from_file(path)
      File.readlines(path).each do |line|
        values = line.split("=")
        key = values[0]
        value = values[1, values.length - 1 ].map {|v| v.strip() }.join('=')
        ENV[key] = value
      end
    end

    # Public: Instantiate a new FormatterLoader object.
    #
    # Returns a new FormatterLoader object.
    def formatter_loader
      @formatter_loader ||= NagiosHerald::FormatterLoader.new
    end

    # Public: Loads all formatter classes.
    #
    # Returns true.
    def load_formatters
      @formatters_loaded ||= formatter_loader.load_formatters
    end

    # Public: Instantiate a new MessageLoader object.
    #
    # Returns a new MessageLoader object.
    def message_loader
      @message_loader ||= NagiosHerald::MessageLoader.new
    end

    # Public: Loads all message classes.
    #
    # Returns true.
    def load_messages
      @messages_loaded ||= message_loader.load_messages
    end

    # Public: The main method from which notifications are generated and sent.
    def announce
      begin
        @options = parse_options
      rescue SystemExit
        logger.fatal "Invalid or missing options\n"
        exit 1
      end

      begin
        # Load the environment if asked for it
        load_env_from_file(@options.env) if @options.env
  
        # Load the config for use globally
        Config.load(@options)
  
        # load the formatters and messages
        load_formatters
        load_messages

        recipients = {}
        if @options.recipients.nil?
          contact_email = get_nagios_var("NAGIOS_CONTACTEMAIL")
          contact_pager = get_nagios_var("NAGIOS_CONTACTPAGER")
          recipients['email'] = contact_email if !contact_email.empty?
          recipients['pager'] = contact_pager if !contact_pager.empty?
        else
          recipients['command_line'] = @options.recipients
        end
        nagios_notification_type = @options.notification_type.nil? ? get_nagios_var("NAGIOS_NOTIFICATIONTYPE") : @options.notification_type
  
        # Log the host and service that's notifying (assuming we can read the environment)
        state_type = get_nagios_var("NAGIOS_SERVICESTATE") != "" ? "SERVICE" : "HOST"
        hostname = get_nagios_var("NAGIOS_HOSTNAME")
        service_desc = get_nagios_var("NAGIOS_SERVICEDESC")
        state = get_nagios_var("NAGIOS_#{state_type}STATE")
        if !service_desc.nil? and !service_desc.empty?
          logger.info "CHECK (SERVICE): #{hostname}/#{service_desc} is #{state}"
        else
          logger.info "CHECK (HOST): #{hostname} is #{state}"
        end

        recipients.each do |recipient_type, recipient|
          contact_name = get_nagios_var("NAGIOS_CONTACTALIAS")
          if recipient.nil? || recipient.eql?("")
            logger.error "No recipient defined for #{contact_name} (type=#{recipient_type})!"
            next
          else
            logger.info "Notifying #{contact_name} (#{recipient}, type=#{recipient_type})"
          end

          # bail if can't identify the message type because we don't know what sort of thing to send
          if !Message.message_types.has_key?(@options.message_type)
            logger.error "Unknown message type: '#{@options.message_type}'"
            logger.error "I'm aware of the following message types:"
            sorted_message_types = Message.message_types.sort_by {|message_type, message_class| message_type}
            sorted_message_types.each do |message_type|
              logger.error " + #{message_type.first}"
            end
            exit 1
          end
          message_class = Message.message_types[@options.message_type]
          message = message_class.new(recipient, @options)

          formatter_class = Formatter.formatters[@options.formatter_name]
          if formatter_class.nil?
              logger.info "Undefined formatter. Defaulting to the base formatter."
              formatter_class = NagiosHerald::Formatter   # default to the base formatter
          end
          formatter = formatter_class.new(@options)

          formatter.generate_message_content
          message.content = formatter.content
          message.send
          formatter.clean_sandbox # clean house
        end
      rescue Exception => e
        logger.fatal "#{e.class}: #{e.message}"
        logger.fatal "COMMAND LINE #{File.basename $0} #{ARGV.join(" ")}"
        if @options[:trace]
          e.backtrace.each do |line|
            logger.fatal "TRACE #{line}"
          end
        else
          logger.fatal "Use --trace for backtrace."
        end
        raise e if @options[:trace] || e.is_a?(SystemExit)
        exit 1
      end
      exit 0
    end

  end
end
