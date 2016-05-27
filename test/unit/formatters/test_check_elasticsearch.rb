require 'minitest/autorun'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/config'
require 'nagios-herald/executor'
require 'nagios-herald/formatters/base'

# Test Formatter::CheckElasticsearch
class TestFormatterCheckElasticsearch < MiniTest::Unit::TestCase

  # TODO: We need a similar set of tests for RECOVERY emails.
  # Initial setup before we execute tests
  def setup
    @options = {}
    @options[:message_type] = 'EMAIL'
    @options[:nagios_url] = "http://nagios.example.com"
    @options[:formatter_name] = 'check_elasticsearch'
    env_file = File.join(File.dirname(__FILE__), '..', '..', 'env_files', 'check_elasticsearch.WARNING')
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
    assert_instance_of NagiosHerald::Formatter::CheckElasticsearch, @formatter
  end

  def test_clean_sandbox
    @formatter.clean_sandbox
    assert !File.directory?(@formatter.sandbox)
  end

end

