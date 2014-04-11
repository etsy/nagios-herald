#!/usr/bin/env ruby

# NOTES
# ClassLoader needs a 'self.inherited' method that creates a hash where the
# keys are the snake_cased names of the classes and the values are the actual classes
# ala https://github.com/opscode/chef/blob/11-stable/lib/chef/knife.rb#L79#L83

module NagiosHerald
  class FormatterLoader

    attr_accessor :formatter_path

    def initialize
      @formatter_path = File.expand_path("formatters", File.dirname(__FILE__))
    end

    # return an array of formatter class files' absolute paths
    def enum_formatter_classes(formatter_path)
      formatter_class_files = Dir.glob(File.expand_path("*.rb", formatter_path))
    end

    # return an array of all class files we care about
    def formatter_classes
      @formatter_classes ||= enum_formatter_classes(@formatter_path)
    end

    # load the formatters
    # bail if we don't find any formatters
    def load_formatters
      if formatter_classes.empty?
        puts "#{$0}: No formatters were found in '#{@formatter_path}'"
        exit 1
      else
        formatter_classes.each do |formatter_class|
          Kernel.load formatter_class
        end
      end
    end

  end
end

