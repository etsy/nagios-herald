module NagiosHerald
  class Formatter
    class Foo < NagiosHerald::Formatter

      def initialize
        puts "in #{self.class.name}"
      end

    end
  end
end
