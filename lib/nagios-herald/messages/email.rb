require 'nagios-herald/messages/base'
require 'mail'

module NagiosHerald
  class Message
    class Email < Message

      attr_accessor :attachments
      attr_accessor :html
      attr_accessor :subject
      attr_accessor :text

      # Public: Initializes a new Message::Email object.
      #
      # recipients - A list of recipients for this message.
      # options - The options hash from Executor.
      # FIXME: Is that ^^ necessary now with Config.config available?
      # 
      # Returns a new Message::Email object.
      def initialize(recipients, options = {})
        @replyto     = options[:replyto]
        @subject     = ""
        @text        = ""
        @html        = ""
        @attachments = []
        super(recipients, options)
      end

      # this is a list of Mail::Part
      # => #<Mail::Part:19564000, Multipart: false, Headers: <Content-Type: ; filename="Rakefile">, <Content-Transfer-Encoding: binary>, <Content-Disposition: attachment; filename="Rakefile">, <Content-ID: <530e1814464a9_3305aaef88979a2@blahblahbl.blah.blah.blah.mail>>>
      # Public: Updates HTML content so that attachments are referenced via the 'cid:' URI scheme and neatly embedded in the body
      # of a(n email) message.
      #
      # attachments - The list of attachments defined in the formatter content hash.
      #
      # Returns the updated HTML content.
      def inline_body_with_attachments(attachments)
        inline_html = @html
        attachments.each do |attachment|
          if (inline_html =~ /#{attachment.filename}/)
            inline_html = inline_html.sub(attachment.filename, "cid:#{attachment.cid}")
          end
        end
        inline_html
      end

      # Public: Generates the text portion of the content hash.
      #
      # Returns the full text portion of the content hash.
      def curate_text
        @text += self.content[:text][:host_info]
        @text += self.content[:text][:state_info]
        @text += self.content[:text][:additional_info]
        @text += self.content[:text][:action_url]
        @text += self.content[:text][:notes]
        @text += self.content[:text][:additional_details]
        @text += self.content[:text][:recipients_email_link]
        @text += self.content[:text][:notification_info]
        @text += self.content[:text][:alert_ack_url]
      end

      # Public: Generates the HTML portion of the content hash.
      #
      # Returns the full HTML portion of the content hash.
      def curate_html
        @html += self.content[:html][:host_info]
        @html += self.content[:html][:state_info]
        @html += self.content[:html][:additional_info]
        @html += self.content[:html][:action_url]
        @html += self.content[:html][:notes]
        @html += self.content[:html][:additional_details]
        @html += self.content[:html][:recipients_email_link]
        @html += self.content[:html][:notification_info]
        @html += self.content[:html][:alert_ack_url]
      end

      # Public: Prints the subject, text and HTML content to the terminal.
      # Useful for debugging.
      #
      # Returns nothing.
      def print
        puts "------------------"
        puts "Subject : #{@subject}"
        puts "------------------"
        puts @text if !@text.empty?
        puts @html if !@html.empty?
      end

      # Public: Sends the email message.
      #
      # Returns nothing.
      def send
        curate_text
        curate_html
        if @no_send
          self.print
          return
        end

        @subject = self.content[:subject]
        mail = Mail.new({
          :from  => @replyto,
          :to    => @recipients,
          :subject => @subject,
          :content_type => 'multipart/alternative'
        })

        text_content = @text
        text_part = Mail::Part.new do
          body text_content
        end

        mail.add_part(text_part)

        html_part = Mail::Part.new do
          content_type 'multipart/related;'
        end

        # Load the attachments
        @attachments = self.content[:attachments]
        @attachments.each do |attachment|
          html_part.attachments[attachment] = File.read(attachment)
        end

        if @html != ""
          # Inline the attachment if need be
          inline_html = inline_body_with_attachments(html_part.attachments)
          html_content_part = Mail::Part.new do
            content_type 'text/html; charset=UTF-8'
            body     inline_html
          end
          html_part.add_part(html_content_part)
        end

        mail.add_part(html_part)

        mail.deliver!
      end

    end
  end
end