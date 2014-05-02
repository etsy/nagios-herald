# looks like this code came from
# http://stackoverflow.com/questions/917566/ruby-share-logger-instance-among-module-classes

require "logger"

module NagiosHerald
  module Logging

    def logger
    @logger ||= Logging.logger_for(self.class.name)
    end

    # Use a hash class-ivar to cache a unique Logger per class:
    # "ivar" = fancy term for "instance variable"
    # do we want this? or a global logger?
    @loggers = {}

    extend self

    # effectively sets the progname
    def logger_for(classname)
      @loggers[classname] ||= configure_logger_for(classname)
    end

    # instantiates a Logger instance
    def configure_logger_for(classname)
      logfile = Config.logfile ? Config.logfile : STDOUT
      # TODO: check the command line options to determine if a logfile was specified
      # TODO TODO: Config should merge command line options on top of config values
      logger = Logger.new(logfile)
      logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      logger.progname = "#{File.basename $0} (#{classname})"
      logger.formatter = proc { |severity, datetime, progname, msg|
        "[#{datetime}] #{severity} -- #{progname}: #{msg}\n"
      }
      logger
    end

  end
end
