# Load all Message classes similar to how messageLoader does its thang.
module NagiosHerald
  class MessageLoader
  include NagiosHerald::Logging

    attr_accessor :builtin_message_path
    attr_accessor :custom_message_path

    # Public: Initialize the message loader module.
    #
    # Adds the path to the built-in message classes to the module variable
    # @builtin_message_paths.
    #
    # Adds the path to custom message classes to the module variable
    # @custom_message_path if that option is passed to `nagios-herald`
    # via '-M|--message-dir' on the command line or via the 'message-dir'
    # option in the configuration file.
    def initialize
      @builtin_message_path = File.expand_path("messages", File.dirname(__FILE__))
      @custom_message_path  = Config.config['message_dir'] if Config.config['message_dir']
    end

    # Public: Enumerate the available message class files (both the builtin
    # classes and those included with the message_dir config).
    #
    # Returns an array of the class files' absolute paths
    def enum_message_class_files
      message_class_files = {}

      # Find builtin message classes first
      builtin_message_class_files = Dir.glob(File.expand_path("*.rb", builtin_message_path))
      builtin_message_class_files.each do |builtin_file|
        message_class_files [File.basename(builtin_file)] = builtin_file
      end

      # If we've been told about custom message classes, add them to the array.
      # If there are conflicts, naively merge them, giving priority to the
      # custom message classes.
      if @custom_message_path
        custom_message_class_files = Dir.glob(File.expand_path("*.rb", custom_message_path))
        custom_message_class_files.each do |custom_file|
          message_class_files [File.basename(custom_file)] = custom_file
        end
      end

      # Return an array of the available messages
      message_class_files.values
    end

    # Public: Return an array of class files' paths (both built-in and custom).
    def message_class_files
      @message_class_files ||= enum_message_class_files
    end

    # Public: Load the messages into the namespace.
    # A message can then easily be instantiated later.
    def load_messages
      if message_class_files.empty?
        if @custom_message_path
          logger.fatal "#{$0}: No messages were found in '#{@message_path}'" \
          " or '#{@custom_message_path}' (as defined by the 'message_dir' option)"
        else
          logger.fatal "#{$0}: No messages were found in '#{@message_path}'"
        end
        exit 1
      else
        message_class_files.each do |message_class_file|
          Kernel.load message_class_file
        end
      end
    end

  end
end

