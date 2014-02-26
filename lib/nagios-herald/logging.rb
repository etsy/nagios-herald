require "logger"

module NagiosHerald
  module Logging
    def logger
    @logger ||= Logging.logger_for(self.class.name)
    end

    # Use a hash class-ivar to cache a unique Logger per class:
    @loggers = {}

    class << self
      def logger_for(classname)
        @loggers[classname] ||= configure_logger_for(classname)
      end

      def configure_logger_for(classname)
        logger = Logger.new(STDOUT)
        logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        logger.progname = classname
        logger.formatter = proc { |severity, datetime, progname, msg|
          "[#{datetime}] #{severity} -- #{progname}: #{msg}\n"
        }
        logger
      end
    end
  end
end
