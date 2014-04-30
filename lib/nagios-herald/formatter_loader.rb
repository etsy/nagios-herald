#!/usr/bin/env ruby

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

    attr_accessor :formatter_path

    def initialize
      # TODO: add support for @options.formatter_path
      @formatter_path = File.expand_path("formatters", File.dirname(__FILE__))
    end

    # Public: Enumerate the available formatter class files.
    #
    # Returns an array of the class files' absolute paths
    def enum_formatter_class_files(formatter_path)
      formatter_class_files = Dir.glob(File.expand_path("*.rb", formatter_path))
    end

    # Public: Return an array of class files' paths.
    def formatter_class_files
      @formatter_class_files ||= enum_formatter_class_files(@formatter_path)
    end

    # Public: Load the formatters into the namespace.
    # A formatter can then easily be instantiated later.
    def load_formatters
      if formatter_class_files.empty?
        puts "#{$0}: No formatters were found in '#{@formatter_path}'"
        exit 1
      else
        formatter_class_files.each do |formatter_class_file|
          Kernel.load formatter_class_file
        end
      end
    end

  end
end

