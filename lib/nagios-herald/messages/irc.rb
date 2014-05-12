require 'nagios-herald/messages/base'
# probs need socket here

module NagiosHerald
  class Message
    class IRC < Message

      attr_accessor :text

      # Public: Initializes a new Message::IRC object.
      #
      # recipients - A list of recipients for this message.
      # options - The options hash from Executor.
      # FIXME: Is that ^^ necessary now with Config.config available?
      #
      # Returns a new Message::IRC object.
      def initialize(recipients, options = {})
        @text = ""
        super(recipients, options)
      end

      # Public: Generates the text portion of the content hash.
      #
      # Returns the full text portion of the content hash.
      def curate_text
        # FIXME: Gonna need to chomp newlines
        @text += self.content[:text][:host_info]
        @text += self.content[:text][:state_info]
        @text += self.content[:text][:alert_ack_url]
      end

      # Public: Prints the text content to the terminal.
      # Useful for debugging.
      #
      # Returns nothing.
      def print
        puts @text
      end

      # Public: Sends the IRC message.
      #
      # Returns nothing.
      def send
        curate_text
        if @no_send
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

