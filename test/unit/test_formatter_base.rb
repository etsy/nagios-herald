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
# more tests to be written...
#    def host_info
#    def state_info
#    def notification_info
#    def additional_info
#    def additional_details
#    def notes
#    def action_url
#    def short_state_detail
#    def recipients_email_link
#    def ack_info
#    def short_ack_info
#    def alert_ack_url
#    def generate_section(section, *section_style_args)
#    def generate_problem_content
#    def generate_recovery_content
#    def generate_ack_content
#    def generate_content(nagios_notification_type)
#    def generate_message_content
#    def get_sandbox_path
#    def clean_sandbox

end
