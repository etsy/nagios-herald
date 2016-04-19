# Load all Helper classes.
module NagiosHerald
  class HelperLoader
  include NagiosHerald::Logging

    attr_accessor :builtin_helper_path
    attr_accessor :custom_helper_path

    # Public: Initialize the helper loader module.
    #
    # Adds the path to the built-in helper classes to the module variable
    # @builtin_helper_paths.
    #
    # Adds the path to custom helper classes to the module variable
    # @custom_helper_path if that option is passed to `nagios-herald`
    # via '-H|--helper-dir' on the command line or via the 'helper-dir'
    # option in the configuration file.
    def initialize
      @builtin_helper_path = File.expand_path("helpers", File.dirname(__FILE__))
      @custom_helper_path  = Config.config['helper_dir'] if Config.config['helper_dir']
    end

    # Public: Enumerate the available helper class files (both the builtin
    # classes and those included with the helper_dir config).
    #
    # Returns an array of the class files' absolute paths
    def enum_helper_class_files
      helper_class_files = {}

      # Find builtin helper classes first
      builtin_helper_class_files = Dir.glob(File.expand_path("*.rb", builtin_helper_path))
      builtin_helper_class_files.each do |builtin_file|
        helper_class_files [File.basename(builtin_file)] = builtin_file
      end

      # If we've been told about custom helper classes, add them to the array.
      # If there are conflicts, naively merge them, giving priority to the
      # custom helper classes.
      if @custom_helper_path
        custom_helper_class_files = Dir.glob(File.expand_path("*.rb", custom_helper_path))
        custom_helper_class_files.each do |custom_file|
          helper_class_files [File.basename(custom_file)] = custom_file
        end
      end

      # Return an array of the available helpers
      helper_class_files.values
    end

    # Public: Return an array of class files' paths (both built-in and custom).
    def helper_class_files
      @helper_class_files ||= enum_helper_class_files
    end

    # Public: Load the helper into the namespace.
    # A helper can then easily be instantiated later.
    def load_helpers
      if helper_class_files.empty?
        if @custom_helper_path
          logger.fatal "#{$0}: No helpers were found in '#{@builtin_helper_path}'" \
          " or '#{@custom_helper_path}' (as defined by the '-H/--helper_dir' option)"
        else
          logger.fatal "#{$0}: No helpers were found in '#{@builtin_helper_path}'"
        end
        exit 1
      else
        helper_class_files.each do |helper_class_file|
          Kernel.load helper_class_file
        end
      end
    end

  end
end

