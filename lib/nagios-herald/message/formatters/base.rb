# base formatter
require 'nagios-herald/formatter_loader'
require 'ap'

module NagiosHerald
  class Message
    class Formatter

      # when instansiated, load all formatters
      def initialize
        formatter_loader = NagiosHerald::FormatterLoader.new
        formatter_files = formatter_loader.load_formatters
      end

      def self.formatters
        @@formatters ||= {}
      end
  
      # when subclassed formatters are instantiated, add them to the @@formatters hash
      # the key is the downcased and snake_cased name of the class file (i.e. check_disk)
      # and the value is the actual class (i.e. CheckDisk) so that we can easily
      # instantiate formatters when we know the formatter name
      def self.inherited(subclass)
        puts "#{subclass} inherited from #{self.name}!" # debug
        subclass_base_name = subclass.name.split('::').last
        puts "subclass base name: #{subclass_base_name}"    # debug
        subclass_base_name.gsub!(/[A-Z]/) { |s| "_" + s } # replace uppercase with underscore and lowercase
        subclass_base_name.downcase!
        subclass_base_name.sub!(/^_/, "")   # strip the leading underscore
        puts "snake_case: #{subclass_base_name}"    # debug
        formatters[subclass_base_name] = subclass
        ap formatters   # debug
      end

    end
  end
end
