require 'nagios-herald/messages/base'
require 'mail'

module NagiosHerald
  class Message
    class Pager < Message

      attr_accessor :subject
      attr_accessor :text

      # Public: Initializes a new Message::Pager object.
      #
      # recipients - A list of recipients for this message.
      # options - The options hash from Executor.
      # FIXME: Is that ^^ necessary now with Config.config available?
      #
      # Returns a new Message::Pager object.
      def initialize(recipients, options = {})
        @replyto     = options[:replyto]
        @subject     = ""
        @text        = ""
        super(recipients, options)
      end

      # Public: Generates the text portion of the content hash.
      #
      # Returns the full text portion of the content hash.
      def curate_text
        notification_type = get_nagios_var('NAGIOS_NOTIFICATIONTYPE')
        if notification_type.eql?('ACKNOWLEDGEMENT')
          @text += self.content[:text][:ack_info]
        else
          @text += self.content[:text][:additional_info]
        end
      end

      # Public: Prints the subject and text content to the terminal.
      # Useful for debugging.
      #
      # Returns nothing.
      def print
        puts "------------------"
        puts "Subject : #{@subject}"
        puts "------------------"
        puts @text
      end

      # Public: Sends the pager message.
      #
      # Returns nothing.
      def send
        curate_text
        if @no_send
          self.print
          return
        end

        @subject = self.content[:subject]
        mail = Mail.new({
          :from    => @replyto,
          :to      => @recipients,
          :subject => @subject,
          :body    => @text
        })

        mail.deliver!
      end
    end
  end
end

