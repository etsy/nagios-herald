require 'minitest/autorun'

# I assume cat'ing to the LOAD path goes away when we're a real gem.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/executor'

# Test the Executor class.
class TestExecutorIcingaVariables < MiniTest::Unit::TestCase
  include NagiosHerald::Util

  # initial setup before we execute tests
  def setup
    @executor = NagiosHerald::Executor.new
    @options = {}
    @options[:env] = File.join(File.dirname(__FILE__), '..', 'env_files', 'check_disk.CRITICAL_ICINGA')
  end

  def teardown
    # reset the config to empty to avoid polluting the static data for other tests
    NagiosHerald::Config.config = {}
  end

  # Read Icinga environment variables.
  def test_icinga_variables
    NagiosHerald::Config.config['icinga'] = true
    @executor.load_env_from_file(@options[:env])
    assert_equal "ops@example.com", get_nagios_var('NAGIOS_CONTACTEMAIL')
    assert_equal "ops@example.com", get_nagios_var('ICINGA_CONTACTEMAIL')
    assert_equal "PROBLEM", get_nagios_var('NAGIOS_NOTIFICATIONTYPE')
  end

end
