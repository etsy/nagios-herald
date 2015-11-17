require 'minitest/autorun'
require 'mail'

# I assume cat'ing to the LOAD path goes away when we're a real gem.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/messages/pager'

# Test Formatter::Base.
class TestMessagePager < MiniTest::Unit::TestCase

  # TODO: We need a similar set of tests for RECOVERY pages.
  # Initial setup before we execute tests
  def setup
    @recipient = 'ops@example.com'
    @options = {:replyto => 'nagios@example.com'}
    @message = NagiosHerald::Message::Pager.new(@recipient, @options)
    @message.content = {
        :attachments => [],
        :html => {
            :host_info => "<div style=''><br><b>Host</b>: web.example.com <b>Service</b>: Disk Space<br/><br></div>",
            :state_info => "<div style=''>State is now: <b><font style='color:red'>CRITICAL</font></b> for <b>0d 0h 5m 12s</b> (was CRITICAL) after <b>3 / 3</b> checks<br/><br></div>",
            :additional_info => "<div style=''><b>Additional Info</b>: DISK CRITICAL - free space: / 7002 MB (18% inode 60%): /data 16273093 MB (26% inode 99%):<br><br></div>",
            :action_url => "<div style=''><b>Action URL</b>: http://runbook.example.com/disk_space_alerts.html<br><br></div>",
            :notes => "<div style=''></div>",
            :additional_details => "<div style=''><b>Additional Details</b>: <pre>\nTHRESHOLDS - WARNING:15%;CRITICAL:20%;\n\nFilesystem            Size  Used Avail Use% Mounted on\n/dev/vda               40G   31G  6.9G  82% /\ntmpfs                 2.5G   83M  2.4G   4% /dev/shm\nnfs.example.example.com:/mnt/user/homes\n                       59T   43T   16T  74% /data\n</pre><br><br></div>",
            :recipients_email_link => "<div style=''>Sent to ops<br><br></div>",
            :notification_info => "<div style=''>Notification sent at: Thu May 16 21:06:38 UTC 2013 (notification number 1)<br><br></div>",
            :alert_ack_url => "<div style=''>Acknowledge this alert: http://nagios.example.com/nagios/cgi-bin/cmd.cgi?cmd_typ=34&host=web.example.com&service=Disk%20Space<br>Alternatively, <b>reply</b> to this message with the word '<b><font color='green'>ack</font></b>' in the body to acknowledge the alert.<br></div>"
        },
        :subject => "PROBLEM Service web.example.com/Disk Space is CRITICAL",
        :text => {
            :host_info => "Host: web.example.com Service: Disk Space\n\n",
            :state_info => "State is now: CRITICAL for 0d 0h 5m 12s (was CRITICAL) after 3 / 3 checks\n\n",
            :additional_info => "Additional Info: DISK CRITICAL - free space: / 7002 MB (18% inode 60%): /data 16273093 MB (26% inode 99%):\n\n",
            :action_url => "Action URL: http://runbook.example.com/disk_space_alerts.html\n\n",
            :notes => "",
            :additional_details => "Additional Details: \nTHRESHOLDS - WARNING:15%;CRITICAL:20%;\n\nFilesystem            Size  Used Avail Use% Mounted on\n/dev/vda               40G   31G  6.9G  82% /\ntmpfs                 2.5G   83M  2.4G   4% /dev/shm\nnfs.example.example.com:/mnt/user/homes\n                       59T   43T   16T  74% /data\n\n",
            :recipients_email_link => "Sent to ops\n\n",
            :notification_info => "Notification sent at: Thu May 16 21:06:38 UTC 2013 (notification number 1)\n\n",
            :alert_ack_url => "Acknowledge this alert: http://nagios.example.com/nagios/cgi-bin/cmd.cgi?cmd_typ=34&host=web.example.com&service=Disk%20Space\nAlternatively, reply to this message with the word 'ack' in the body to acknowledge the alert.\n"
        },
        :short_text => {
            :host_info => "web.example.com/Disk Space\n\n",
            :state_info => "CRITICAL for 0d 0h 5m 12s (was CRITICAL) after 3 / 3 checks\n\n",
            :additional_info => "DISK CRITICAL - free space: / 7002 MB (18% inode 60%): /data 16273093 MB (26% inode 99%):\n\n",
            :action_url => "Action URL: http://runbook.example.com/disk_space_alerts.html\n\n",
            :notes => "",
            :additional_details => "THRESHOLDS - WARNING:15%;CRITICAL:20%;\n\nFilesystem            Size  Used Avail Use% Mounted on\n/dev/vda               40G   31G  6.9G  82% /\ntmpfs                 2.5G   83M  2.4G   4% /dev/shm\nnfs.example.example.com:/mnt/user/homes\n                       59T   43T   16T  74% /data\n\n",
            :recipients_email_link => "Sent to ops\n\n",
            :notification_info => "Notification sent at: Thu May 16 21:06:38 UTC 2013 (notification number 1)\n\n",
            :alert_ack_url => "Acknowledge this alert: http://nagios.example.com/nagios/cgi-bin/cmd.cgi?cmd_typ=34&host=web.example.com&service=Disk%20Space\nAlternatively, reply to this message with the word 'ack' in the body to acknowledge the alert.\n"
        }
    }
  end

  def teardown
  end

  # Test that we have a new NagiosHerald::Message::Pager object.
  def test_new_message_pager
    assert_instance_of NagiosHerald::Message::Pager, @message
  end

  def test_message_delivery
    # This test depends on the mailcatcher gem being installed and
    # `mailcatcher` running. `mailcatcher` runs locally on tcp/1025.
    # NOTE: NagiosHerald::Message::Pager#send calls #build_message before
    # delivering the message. We need to override some SMTP settings for this
    # test so we call #deliver! here.
    mail = @message.build_message
    # Set 'return_response' to true so that #deliver! returns the
    # Net::SMTP::Response for us to validate.
    mail.delivery_method :smtp, {:address => 'localhost', :port => 1025, :return_response => true}
    response = mail.deliver!
    assert_equal "250", response.status
  end

end

