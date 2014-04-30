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
    # Returns a hash of the parsed config file.
    def load(options = {})
      abort("Config file not found #{options.config_file}") unless File.exists? options.config_file
      @config = AppConf.new
      @config.load(options.config_file)
      @config
    end

    # Public: Look up config items in the @config hash.
    # Use some Ruby magic to make it so.
    def method_missing(item_name, *args, &block)
      @config[item_name.to_sym] || fail(NoMethodError, "Unknown config item #{item_name}", caller)
    end

  end
end
