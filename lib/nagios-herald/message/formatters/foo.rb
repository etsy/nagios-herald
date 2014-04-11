module NagiosHerald
  class Message
    class Formatter
      class Foo < Formatter

        def initialize
          puts "in #{self.class.name}"
        end

      end
    end
  end
end
