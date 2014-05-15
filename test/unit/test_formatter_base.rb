require 'minitest/autorun'

# I assume cat'ing to the LOAD path goes away when we're a real gem.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/config'
require 'nagios-herald/executor'
require 'nagios-herald/formatters/base'

# Test Formatter::Base.
class TestFormatterBase < MiniTest::Unit::TestCase
#  include NagiosHerald::Util

  # Initial setup before we execute tests
  def setup
    @options = {}
    @options[:message_type] = 'EMAIL'
    @options[:nagios_url] = "http://nagios.example.com"
    @formatter = NagiosHerald::Formatter.new(@options)
  end

  # Test that we have a new NagiosHerald::Formatter object.
  def test_new_formatter
    assert_instance_of NagiosHerald::Formatter, @formatter
  end

end
