require 'nagios-herald/messages/base'
# probs need socket here

module NagiosHerald
  class Message
    class IRC < Message
      attr_accessor :text

      def initialize(recipients, options = {})
        @text = ""
        super(recipients, options)
      end

      def curate_text
        # FIXME: Gonna need to chomp newlines
        @text += self.content[:text][:host_info]
        @text += self.content[:text][:state_info]
        @text += self.content[:text][:alert_ack_url]
      end

      def print
        puts @text
      end

      def send
        curate_text
        if @nosend
          self.print
          return
        end

        # TODO: Actually make this send to an IRC server
        # I expect the IRC server will be a value in the config
        self.print
      end

    end
  end
end

