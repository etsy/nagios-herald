require 'test/unit'
require 'ostruct'

class EmailMessageTestCase < Test::Unit::TestCase
  def setup
    @email = NagiosHerald::EmailMessage.new(nil)
    @pager_email = NagiosHerald::EmailMessage.new(nil, options={:pager_mode => true})
  end
  # will always add text to the email's text
  def test_add_text
    expected = "some text"
    @email.add_text(expected)
    assert_equal(expected, @email.text)
  end

  # Should not add html in pager mode
  def test_add_html_in_pager_mode
    assert @pager_email.instance_eval { @pager_mode }
    expected = "<h1>Some HTML</h1>"
    @pager_email.add_html expected
    assert_empty @pager_email.html
  end
 
  # should add html not in pager mode
  def test_add_html_not_in_pager_mode
    refute @email.instance_eval { @pager_mode }
    expected = "<h2>More HTML</h2>"
    @email.add_html expected
    assert_equal(expected, @email.html)
  end

  # should add attachment path to a list of attachments
  # Note: these might be misleading: actual files are probably expected
  def test_add_attachment
    expected = ['/var/img/something.png']
    @email.add_attachment expected[0]
    assert_equal(expected, @email.instance_eval{@attachments})
  end
  
  # given a list add each item on the list to the path of attachments
  def test_add_attachments
    expected = ['/first/img.png', 'second/img/file.png']
    @email.add_attachments expected
    assert_equal(expected, @email.instance_eval{@attachments})
  end

  # given a list of Mail::Part objects replace their filename in the HTML with the attachment's cid and return the html
  def test_inline_body_with_attachments
    a1 = OpenStruct.new
    a1.filename = 'foo.png'
    a1.cid = '2342e3131a4_2131aefef5232e2@some.host.mail'
    attachments = [a1]
    @email.add_html %Q(this is an <img src="foo.png" />)
    inline = @email.inline_body_with_attachments attachments
    assert_equal(%Q(this is an <img src="cid:#{a1.cid}" />), inline)
  end

  # get the subject of the email
  def test_has_content
    expected = "Alert!"
    @email.subject = expected
    assert_equal(expected, @email.has_content)
  end

  # should see a representation of the email
  def test_print
    @email.subject = "Alert!"
    @email.add_text "Your server is down!"
    @email.add_html "<h1>Your server is down!</h1>"
    out, err = capture_io do
      @email.print
    end
    expected = <<eos
Email text content
------------------
Subject : #{@email.subject}
------------------
#{@email.text}
------------------
Email html content saved as mail.html
eos
    assert_equal(expected, out)
  end
end
