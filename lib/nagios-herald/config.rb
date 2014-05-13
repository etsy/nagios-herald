require 'app_conf'

module NagiosHerald
  module Config
    extend self

    @config = {}
    attr_accessor :config

    # Public: Load the configuration file for use globally.
    #
    # options - The options hash built from command-line arguments.
    #
    # Returns a hash of the parsed config file merged with the command line options.
    def load(options = {})
      abort("Config file not found #{options['config_file']}") unless File.exists? options['config_file']
      @config = AppConf.new
      @config.load(options['config_file'])
      @config = @config.to_hash
      @config.merge!(options)   # runtime options should override
      @config
    end

  end
end
