require 'minitest/autorun'

# I assume cat'ing to the LOAD path goes away when we're a real gem.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/config'

# Test the Config module.
class TestConfig < MiniTest::Unit::TestCase
#  include NagiosHerald::Util

  # Initial setup before we execute tests
  def setup
    @options = {}
    @options['config_file'] = File.expand_path(File.join(File.dirname(__FILE__), '..', 'etc', 'config.yml.example'))
    @options['message_type'] = "pager"
  end

  # Make sure we can load the config and read values from it.
  # Read values from command-line options and the config file.
  def test_load_config
    NagiosHerald::Config.load(@options)
    assert_equal "pager", NagiosHerald::Config.config['message_type']                       # Command line
    assert_equal "ganglia.example.com", NagiosHerald::Config.config['servers']['ganglia']   # Config file
    assert_equal "splunkuser",  NagiosHerald::Config.config['splunk']['username']           # Config file
  end

end
