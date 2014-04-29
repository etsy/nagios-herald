module NagiosHerald
  class Formatter
    class Foo < NagiosHerald::Formatter

      # might we do away with this and fall back to the superclass's #initialize?
      def initialize
        puts "in #{self.class.name}"
        super
      end

      def generate_subject
        add_text "I added text!"
        self.text
      end

      def generate_body
        nagios_notification_type = get_nagios_var('NAGIOS_NOTIFICATIONTYPE')
        generate_content(nagios_notification_type)
      end

    end
  end
end
