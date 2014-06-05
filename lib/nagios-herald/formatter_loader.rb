# This is why open source rocks my worl'! I lifted this pattern of loading classes
# from the good folks at Chef. The gist is that a given directory contains a set
# of class files that we want to load into the namespace for use later.
# This allows us to build up a hash of the classes where the key is the class file
# name and the value is the class itself. We can then instantiate an object of a
# given class dynamically.
# See https://github.com/opscode/chef/blob/11-stable/lib/chef/knife.rb#L79#L83 for
# an example of this in action via the #inherited method.
module NagiosHerald
  class FormatterLoader
  include NagiosHerald::Logging

    attr_accessor :builtin_formatter_path
    attr_accessor :custom_formatter_path

    # Public: Initialize the formatter loader module.
    # Adds the path to the built-in formatters to the module variable @formatter_paths.
    # Adds the path to custom formatters if that option is passed to `nagios-herald`
    # via '-F|--formatter-dir' on the command line or via the 'formatter-dir'
    # option in the configuration file.
    def initialize
      @builtin_formatter_path = File.expand_path("formatters", File.dirname(__FILE__))
      @custom_formatter_path = Config.config['formatter_dir'] if Config.config['formatter_dir']
    end

    # Public: Enumerate the available formatter class files.
    #
    # Returns a hash of the class files' absolute paths whose
    # key is the formatter file's basename and the 
    # value is the full path to the file.
    def enum_formatter_class_files
      formatter_class_files = {}

      # Iterate over the builtin formatters first.
      builtin_formatter_class_files = Dir.glob(File.expand_path("*.rb", @builtin_formatter_path))
      builtin_formatter_class_files.each do |builtin_formatter_class_file|
        formatter_class_files[File.basename(builtin_formatter_class_file)] = builtin_formatter_class_file
      end
      # If we've been told about custom formatters, add them to the hash.
      # If there are conflicts, naively merge them, with the custom formatters getting
      # priority.
      if @custom_formatter_path
        custom_formatters = {}
        custom_formatter_class_files = Dir.glob(File.expand_path("*.rb", @custom_formatter_path))
        custom_formatter_class_files.each do |custom_formatter_class_file|
          custom_formatters[File.basename(custom_formatter_class_file)] = custom_formatter_class_file
        end
        formatter_class_files.merge!(custom_formatters)
      end
      formatter_class_files
    end

    # Public: An array of class files' paths.
    #
    # Returns an array of class files' paths.
    def formatter_class_files
      @formatter_class_files ||= enum_formatter_class_files
    end

    # Public: Load the formatters into the namespace.
    # A formatter can then easily be instantiated later.
    #
    # Returns nothing but loads the classes into the namespace.
    def load_formatters
      if formatter_class_files.empty?
        if @custom_formatter_path
          puts "#{$0}: No formatters were found in '#{@builtin_formatter_path}'" \
          " or '#{@custom_formatter_path}' (as defined by the 'formatter_dir' option)!"
        else
          puts "#{$0}: No formatters were found in '#{@builtin_formatter_path}'!"
        end
        exit 1
      else
        formatter_class_files.each do |formatter_class, formatter_class_file|
          Kernel.load formatter_class_file
        end
      end
    end

  end
end

