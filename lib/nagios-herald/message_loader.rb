# Load all Message classes similar to how messageLoader does its thang.
module NagiosHerald
  class MessageLoader
  include NagiosHerald::Logging

    attr_accessor :message_path

    def initialize
      # TODO: add support for @options.message_path
      @message_path = File.expand_path("messages", File.dirname(__FILE__))
    end

    # Public: Enumerate the available message class files.
    #
    # Returns an array of the class files' absolute paths
    def enum_message_class_files(message_path)
      message_class_files = Dir.glob(File.expand_path("*.rb", message_path))
    end

    # Public: Return an array of class files' paths.
    def message_class_files
      @message_class_files ||= enum_message_class_files(@message_path)
    end

    # Public: Load the messages into the namespace.
    # A message can then easily be instantiated later.
    def load_messages
      if message_class_files.empty?
        logger.fatal "#{$0}: No messages were found in '#{@message_path}'"
        exit 1
      else
        message_class_files.each do |message_class_file|
          Kernel.load message_class_file
        end
      end
    end

  end
end

