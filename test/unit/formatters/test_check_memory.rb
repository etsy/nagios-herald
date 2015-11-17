require 'minitest/autorun'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/config'
require 'nagios-herald/executor'
require 'nagios-herald/formatters/base'

# Test Formatter::CheckMemory.
class TestFormatterCheckMemory < MiniTest::Unit::TestCase

  # TODO: We need a similar set of tests for RECOVERY emails.
  # Initial setup before we execute tests
  def setup
    @options = {}
    @options[:message_type] = 'EMAIL'
    @options[:nagios_url] = "http://nagios.example.com"
    @options[:formatter_name] = 'check_memory'
    env_file = File.join(File.dirname(__FILE__), '..', '..', 'env_files', 'check_memory.CRITICAL')
    NagiosHerald::Executor.new.load_env_from_file(env_file) # load an env file for testing
    NagiosHerald::Executor.new.load_formatters
    NagiosHerald::Executor.new.load_messages
    formatter_class = NagiosHerald::Formatter.formatters[@options[:formatter_name]]
    @formatter = formatter_class.new(@options)
  end

  def teardown
    # make certain we don't leave tons of empty temp dirs behind
    @formatter.clean_sandbox
  end

  # Test that we have a new NagiosHerald::Formatter object.
  def test_new_formatter
    assert_instance_of NagiosHerald::Formatter::CheckMemory, @formatter
  end

  def test_add_content_basic
    @formatter.add_text('test_add_content', 'This is test text')
    assert_equal 'This is test text', @formatter.content[:text][:test_add_content]
    @formatter.add_html('test_add_content', '<b>This is test HTML</b>')
    assert_equal '<b>This is test HTML</b>', @formatter.content[:html][:test_add_content]
    @formatter.generate_subject
    assert_equal "PROBLEM Service web.example.com/Memory is CRITICAL", @formatter.content[:subject]
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
    assert_equal "<br><b>Host</b>: web.example.com <b>Service</b>: Memory<br/><br>", @formatter.content[:html][:host_info]
    assert_equal "Host: web.example.com Service: Memory\n\n", @formatter.content[:text][:host_info]
  end

  def test_state_info
    @formatter.state_info
    assert_equal "State is now: <b><font style='color:red'>CRITICAL</font></b> for <b>0d 0h 5m 3s</b> (was CRITICAL) after <b>3 / 3</b> checks<br/><br>", @formatter.content[:html][:state_info]
    assert_equal "State is now: CRITICAL for 0d 0h 5m 3s (was CRITICAL) after 3 / 3 checks\n\n", @formatter.content[:text][:state_info]
  end

  def test_notification_info
    @formatter.notification_info
    assert_equal "Notification sent at: Thu May 14 21:06:38 UTC 2014 (notification number 1)<br><br>", @formatter.content[:html][:notification_info]
    assert_equal "Notification sent at: Thu May 14 21:06:38 UTC 2014 (notification number 1)\n\n", @formatter.content[:text][:notification_info]
  end

  def test_additional_info
    @formatter.additional_info
    assert_equal "<b>Additional Info</b>: Memory CRITICAL - 98.1% used (22.986 GB total plus 0.171 GB cached, 0.098 GB reclaimable)<br><br>", @formatter.content[:html][:additional_info]
    assert_equal "Additional Info: Memory CRITICAL - 98.1% used (22.986 GB total plus 0.171 GB cached, 0.098 GB reclaimable)\n\n", @formatter.content[:text][:additional_info]
  end

  def test_additional_details
    @formatter.additional_details
    puts
    assert_equal "<b>Additional Details</b>:<pre><br>TOP 5 PROCESSES BY MEMORY USAGE:<br> %MEM          RSS         USER    PID COMMAND<br><font color='red'>  2.4      1231696        larry   6658 tmux</font><br><font color='orange'>  1.5       777204          moe  32234 tmux/tmux -CC</font><br><font color='orange'>  0.8       399964        curly  12161 /usr/sbin/gmond</font><br><font color='orange'>  0.7       384772         shep   1945 /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib64/mysql/plugin --user=mysql --log-error=/var/lib/mysql/web.example.com.err --pid-file=/var/lib/mysql/web.example.com.pid</font><br><font color='orange'>  0.7       355148         root   1245 SCREEN</font><br></pre><br>", @formatter.content[:html][:additional_details]
    assert_equal "Additional Details:\n#TOP 5 PROCESSES BY MEMORY USAGE:\n %MEM          RSS         USER    PID COMMAND\n  2.4      1231696        larry   6658 tmux\n  1.5       777204          moe  32234 tmux/tmux -CC\n  0.8       399964        curly  12161 /usr/sbin/gmond\n  0.7       384772         shep   1945 /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib64/mysql/plugin --user=mysql --log-error=/var/lib/mysql/web.example.com.err --pid-file=/var/lib/mysql/web.example.com.pid\n  0.7       355148         root   1245 SCREEN\n\n\n", @formatter.content[:text][:additional_details]
  end

  def test_notes
    @formatter.notes
    # There are no notes in the example environment variables.
    assert_equal "", @formatter.content[:html][:notes]
    assert_equal "", @formatter.content[:text][:notes]
  end

  def test_action_url
    @formatter.action_url
    assert_equal "", @formatter.content[:html][:action_url]
    assert_equal "", @formatter.content[:text][:action_url]
  end

  def test_short_state_detail
    @formatter.short_state_detail
    assert_equal "Memory CRITICAL - 98.1% used (22.986 GB total plus 0.171 GB cached, 0.098 GB reclaimable)<br>", @formatter.content[:html][:short_state_detail]
    assert_equal "Memory CRITICAL - 98.1% used (22.986 GB total plus 0.171 GB cached, 0.098 GB reclaimable)\n", @formatter.content[:text][:short_state_detail]
  end

  def test_recipients_email_link
    @formatter.recipients_email_link
    assert_equal "Sent to ops<br><br>", @formatter.content[:html][:recipients_email_link]
    assert_equal "Sent to ops\n\n", @formatter.content[:text][:recipients_email_link]
  end

  def test_ack_info
    @formatter.ack_info
    assert_equal "At Thu May 14 21:06:38 UTC 2014 ops acknowledged web.example.com/Memory.<br><br>Comment: ", @formatter.content[:html][:ack_info]
    assert_equal "At Thu May 14 21:06:38 UTC 2014 ops acknowledged web.example.com/Memory.\n\nComment: ", @formatter.content[:text][:ack_info]
  end

  def test_short_ack_info
    @formatter.short_ack_info
    assert_equal "ops  ack'd Memory on web.example.com.<br>", @formatter.content[:html][:short_ack_info]
    assert_equal "ops  ack'd Memory on web.example.com.\n", @formatter.content[:text][:short_ack_info]
  end

  def test_alert_ack_url
    @formatter.alert_ack_url
    assert_equal "Acknowledge this alert: http://nagios.example.com/nagios/cgi-bin/cmd.cgi?cmd_typ=34&host=web.example.com&service=Memory<br>Alternatively, <b>reply</b> to this message with the word '<b><font color='green'>ack</font></b>' in the body to acknowledge the alert.<br>", @formatter.content[:html][:alert_ack_url]
    assert_equal "Acknowledge this alert: http://nagios.example.com/nagios/cgi-bin/cmd.cgi?cmd_typ=34&host=web.example.com&service=Memory\nAlternatively, reply to this message with the word 'ack' in the body to acknowledge the alert.\n", @formatter.content[:text][:alert_ack_url]
  end

  def test_clean_sandbox
    @formatter.clean_sandbox
    assert !File.directory?(@formatter.sandbox)
  end

end

