require 'mail'

module NagiosHerald
  class EmailMessage
    attr_accessor :subject
    attr_reader :text
    attr_reader :html

    def initialize(recipients, options = {})
      @recipients   = recipients
      @pager_mode   = options[:pager_mode]
      @replyto    = options[:replyto]
      @subject    = nil
      @text     = ""
      @html     = ""
      @attachments  = []
    end

    def add_text(bit)
      @text += bit
    end

    def add_html(bit)
      @html += bit if not @pager_mode
    end

    def add_attachment(path)
      @attachments << path
    end

    def add_attachments(list_of_path)
      @attachments.concat(list_of_path)
    end

    def inline_body_with_attachments(attachments)
      inline_html = @html
      attachments.each do |attachment|
        if (inline_html =~ /#{attachment.filename}/)
          inline_html = inline_html.sub(attachment.filename, "cid:#{attachment.cid}")
        end
      end
      return inline_html
    end

    def has_content
      return @subject
    end

    def print
      puts "Email text content"
      puts "------------------"
      puts "Subject : #{@subject}"
      puts "------------------"
      puts @text

      File.open("mail.html", 'w') { |file| file.write( @html) }
      puts "------------------"
      puts "Email html content saved as mail.html"
    end

    def send
      if not has_content
        puts "Email has not content - exiting"
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