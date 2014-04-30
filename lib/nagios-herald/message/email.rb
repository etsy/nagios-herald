require 'nagios-herald/message/base'
require 'mail'

module NagiosHerald
  class Message
    class Email < Message

      attr_accessor :attachments
      attr_accessor :html
      attr_accessor :subject
      attr_accessor :text

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
      def inline_body_with_attachments(attachments)
        inline_html = @html
        attachments.each do |attachment|
          if (inline_html =~ /#{attachment.filename}/)
            inline_html = inline_html.sub(attachment.filename, "cid:#{attachment.cid}")
          end
        end
        inline_html
      end

      def print
        puts "------------------"
        puts "Subject : #{@subject}"
        puts "------------------"
        puts @body
      end

      def send
        if @nosend
          self.print
          return
        end

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
