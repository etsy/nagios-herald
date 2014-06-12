require 'minitest/autorun'

# I assume cat'ing to the LOAD path goes away when we're a real gem.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/config'
require 'nagios-herald/executor'
require 'nagios-herald/formatters/base'

# Test Formatter::Base.
class TestFormatterBase < MiniTest::Unit::TestCase

  # TODO: We need a similar set of tests for RECOVERY emails.
  # Initial setup before we execute tests
  def setup
    @options = {}
    @options[:message_type] = 'EMAIL'
    @options[:nagios_url] = "http://nagios.example.com"
    @formatter = NagiosHerald::Formatter.new(@options)
    env_file = File.join(File.dirname(__FILE__), '..', 'env_files', 'nagios_vars.EXAMPLE')
    NagiosHerald::Executor.new.load_env_from_file(env_file) # load an env file for testing
  end

  def teardown
    # make certain we don't leave tons of empty temp dirs behind
    @formatter.clean_sandbox
  end

  # Test that we have a new NagiosHerald::Formatter object.
  def test_new_formatter
    assert_instance_of NagiosHerald::Formatter, @formatter
  end

  def test_add_content_basic
    @formatter.add_text('test_add_content', 'This is test text')
    assert_equal 'This is test text', @formatter.content[:text][:test_add_content]
    @formatter.add_html('test_add_content', '<b>This is test HTML</b>')
    assert_equal '<b>This is test HTML</b>', @formatter.content[:html][:test_add_content]
    @formatter.generate_subject
    assert_equal "PROBLEM Service web.example.com/Disk Space is CRITICAL", @formatter.content[:subject]
    attachment_name = "#{@formatter.sandbox}/cat.gif"
    @formatter.add_attachment(attachment_name)
    assert @formatter.content[:attachments].include?(attachment_name), "Failed to attach #{attachment_name} to content hash."
  end

  def test_action_url
    @formatter.action_url
    assert_equal "<b>Action URL</b>: http://runbook.example.com/disk_space_alerts.html<br><br>", @formatter.content[:html][:action_url]
    assert_equal "Action URL: http://runbook.example.com/disk_space_alerts.html\n\n", @formatter.content[:text][:action_url]
  end

  def test_host_info
    @formatter.host_info
    assert_equal "<br><b>Host</b>: web.example.com <b>Service</b>: Disk Space<br/><br>", @formatter.content[:html][:host_info]
    assert_equal "Host: web.example.com Service: Disk Space\n\n", @formatter.content[:text][:host_info]
  end

  def test_state_info
    @formatter.state_info
    assert_equal "State is now: <b><font style='color:red'>CRITICAL</font></b> for <b>0d 0h 5m 12s</b> (was CRITICAL) after <b>3 / 3</b> checks<br/><br>", @formatter.content[:html][:state_info]
    assert_equal "State is now: CRITICAL for 0d 0h 5m 12s (was CRITICAL) after 3 / 3 checks\n\n", @formatter.content[:text][:state_info]
  end

  def test_notification_info
    @formatter.notification_info
    assert_equal "Notification sent at: Thu May 16 21:06:38 UTC 2013 (notification number 1)<br><br>", @formatter.content[:html][:notification_info]
    assert_equal "Notification sent at: Thu May 16 21:06:38 UTC 2013 (notification number 1)\n\n", @formatter.content[:text][:notification_info]
  end

  def test_additional_info
    @formatter.additional_info
    assert_equal "<b>Additional Info</b>: DISK CRITICAL - free space: / 7002 MB (18% inode 60%): /data 16273093 MB (26% inode 99%):<br><br>", @formatter.content[:html][:additional_info]
    assert_equal "Additional Info: DISK CRITICAL - free space: / 7002 MB (18% inode 60%): /data 16273093 MB (26% inode 99%):\n\n", @formatter.content[:text][:additional_info]
  end

  def test_additional_details
    @formatter.additional_details
    assert_equal "<b>Additional Details</b>: <pre>\nTHRESHOLDS - WARNING:15%;CRITICAL:20%;\n\nFilesystem            Size  Used Avail Use% Mounted on\n/dev/vda               40G   31G  6.9G  82% /\ntmpfs                 2.5G   83M  2.4G   4% /dev/shm\nnfs.example.example.com:/mnt/user/homes\n                       59T   43T   16T  74% /data\n</pre><br><br>", @formatter.content[:html][:additional_details]
    assert_equal "Additional Details: \nTHRESHOLDS - WARNING:15%;CRITICAL:20%;\n\nFilesystem            Size  Used Avail Use% Mounted on\n/dev/vda               40G   31G  6.9G  82% /\ntmpfs                 2.5G   83M  2.4G   4% /dev/shm\nnfs.example.example.com:/mnt/user/homes\n                       59T   43T   16T  74% /data\n\n", @formatter.content[:text][:additional_details]
  end

  def test_notes
    @formatter.notes
    # There are no notes in the example environment variables.
    assert_equal "", @formatter.content[:html][:notes]
    assert_equal "", @formatter.content[:text][:notes]
  end

  def test_action_url
    @formatter.action_url
    assert_equal "<b>Action URL</b>: http://runbook.example.com/disk_space_alerts.html<br><br>", @formatter.content[:html][:action_url]
    assert_equal "Action URL: http://runbook.example.com/disk_space_alerts.html\n\n", @formatter.content[:text][:action_url]
  end

  def test_short_state_detail
    @formatter.short_state_detail
    assert_equal "DISK CRITICAL - free space: / 7002 MB (18% inode 60%): /data 16273093 MB (26% inode 99%):<br>", @formatter.content[:html][:short_state_detail]
    assert_equal "DISK CRITICAL - free space: / 7002 MB (18% inode 60%): /data 16273093 MB (26% inode 99%):\n", @formatter.content[:text][:short_state_detail]
  end

  def test_recipients_email_link
    @formatter.recipients_email_link
    assert_equal "Sent to ops<br><br>", @formatter.content[:html][:recipients_email_link]
    assert_equal "Sent to ops\n\n", @formatter.content[:text][:recipients_email_link]
  end

  def test_ack_info
    @formatter.ack_info
    assert_equal "At Thu May 16 21:06:38 UTC 2013 ops acknowledged web.example.com/Disk Space.<br><br>Comment: ", @formatter.content[:html][:ack_info]
    assert_equal "At Thu May 16 21:06:38 UTC 2013 ops acknowledged web.example.com/Disk Space.\n\nComment: ", @formatter.content[:text][:ack_info]
  end

  def test_short_ack_info
    @formatter.short_ack_info
    assert_equal "ops  ack'd Disk Space on web.example.com.<br>", @formatter.content[:html][:short_ack_info]
    assert_equal "ops  ack'd Disk Space on web.example.com.\n", @formatter.content[:text][:short_ack_info]
  end

  def test_alert_ack_url
    @formatter.alert_ack_url
    assert_equal "Acknowledge this alert: http://nagios.example.com/nagios/cgi-bin/cmd.cgi?cmd_typ=34&host=web.example.com&service=Disk%20Space<br>Alternatively, <b>reply</b> to this message with the word '<b><font color='green'>ack</font></b>' in the body to acknowledge the alert.<br>", @formatter.content[:html][:alert_ack_url]
    assert_equal "Acknowledge this alert: http://nagios.example.com/nagios/cgi-bin/cmd.cgi?cmd_typ=34&host=web.example.com&service=Disk%20Space\nAlternatively, reply to this message with the word 'ack' in the body to acknowledge the alert.\n", @formatter.content[:text][:alert_ack_url]
  end

  def test_clean_sandbox
    @formatter.clean_sandbox
    assert !File.directory?(@formatter.sandbox)
  end

end

