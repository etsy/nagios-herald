# looks like this code came from
# http://stackoverflow.com/questions/917566/ruby-share-logger-instance-among-module-classes

require "logger"

module NagiosHerald
  module Logging

    def logger
    @logger ||= Logging.logger_for(self.class.name)
    end

    # Use a hash class-ivar to cache a unique Logger per class:
    @loggers = {}

    extend self

    def logger_for(classname)
      @loggers[classname] ||= configure_logger_for(classname)
    end

    def configure_logger_for(classname)
      logger = Logger.new(STDOUT)
      logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      logger.progname = "#{File.basename $0} (#{classname})"
      logger.formatter = proc { |severity, datetime, progname, msg|
        "[#{datetime}] #{severity} -- #{progname}: #{msg}\n"
      }
      logger
    end

  end
end
