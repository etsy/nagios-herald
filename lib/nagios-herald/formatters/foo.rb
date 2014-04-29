module NagiosHerald
  class Formatter
    class Foo < NagiosHerald::Formatter

      # might we do away with this and fall back to the superclass's #initialize?
      def initialize
        puts "in #{self.class.name}"
        super
      end

      # Optionally override #generate_subject
      # Account for message type (email, pager, IRC) and act accordingly
      #def generate_subject
      #  add_text "I added text!"
      #  self.text
      #end

      # Optionally override #generate_body
      #def generate_body
      #end

    end
  end
end
