require 'minitest/autorun'

# I assume cat'ing to the LOAD path goes away when we're a real gem.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/config'
require 'nagios-herald/executor'
require 'nagios-herald/formatters/base'
require 'ap'    # temp, for debugging

# Test Formatter::Base.
class TestFormatterBase < MiniTest::Unit::TestCase
#  include NagiosHerald::Util

  # Initial setup before we execute tests
  def setup
    @options = {}
    @options[:message_type] = 'EMAIL'
    @options[:nagios_url] = "http://nagios.example.com"
    @formatter = NagiosHerald::Formatter.new(@options)
    env_file = File.join(File.dirname(__FILE__), '..', 'env_files', 'nagios_vars.EXAMPLE')
    NagiosHerald::Executor.new.load_env_from_file(env_file) # load an env file for testing
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
    assert_equal "Action URL: http://runbook.example.com/disk_space_alerts.html\n\n", @formatter.content[:text][:action_url]
    assert_equal "<b>Action URL</b>: http://runbook.example.com/disk_space_alerts.html<br><br>", @formatter.content[:html][:action_url]
  end

  def test_host_info
    @formatter.host_info
  end

  def test_state_info
    @formatter.state_info
  end

  def test_notification_info
    @formatter.notification_info
  end

  def test_additional_info
    @formatter.additional_info
  end

  def test_additional_details
    @formatter.additional_details
  end

  def test_notes
    @formatter.notes
  end

  def test_action_url
    @formatter.action_url
  end

  def test_short_state_detail
    @formatter.short_state_detail
  end

  def test_recipients_email_link
    @formatter.recipients_email_link
  end

  def test_ack_info
    @formatter.ack_info
  end

  def test_short_ack_info
    @formatter.short_ack_info
  end

  def test_alert_ack_url
    @formatter.alert_ack_url
  end

  def test_generate_problem_content
    @formatter.generate_problem_content
  end

  def test_generate_recovery_content
    @formatter.generate_recovery_content
  end

  def test_generate_ack_content
    @formatter.generate_ack_content
  end

  def test_generate_content
    @formatter.generate_content(nagios_notification_type)
  end

  def test_generate_message_content
    @formatter.generate_message_content
  end

  def test_get_sandbox_path
    @formatter.get_sandbox_path
  end

  def test_clean_sandbox
    @formatter.clean_sandbox
  end

end

