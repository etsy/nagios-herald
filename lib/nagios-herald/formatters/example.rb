module NagiosHerald
  class Formatter
    class Example < NagiosHerald::Formatter

    # ovrerride Formatter::Base#additional_details
    def additional_details
      section = __method__  # content section is named after the method
      html = ""
      text = ""
      text += "Example text"
      html += "Example <b>HTML</b>"
      add_text(section, text)
      add_html(section, html)
      format_line_break(section)    # trailing line break
    end

    end
  end
end
