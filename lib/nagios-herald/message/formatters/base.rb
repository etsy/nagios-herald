# base formatter
require 'nagios-herald/formatter_loader'
require 'ap'

module NagiosHerald
  class Message
    class Formatter

      def initialize
        formatter_loader = NagiosHerald::FormatterLoader.new
        formatter_files = formatter_loader.load_formatters
      end

      def self.formatters
        @@formatters ||= {}
      end
  
      def self.inherited(subclass)
        puts "#{subclass} inherited from #{self.name}!"
        subclass_base_name = subclass.name.split('::').last
        puts "subclass base name: #{subclass_base_name}"
        subclass_base_name.gsub!(/[A-Z]/) { |s| "_" + s } # replace uppercase with underscore and lowercase
        subclass_base_name.downcase!
        subclass_base_name.sub!(/^_/, "")
        puts "snake_case: #{subclass_base_name}"
        formatters[subclass_base_name] = subclass
        ap formatters
      end

    end
  end
end
