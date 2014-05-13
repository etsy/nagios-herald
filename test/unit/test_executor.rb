require 'minitest/autorun'

# I assume cat'ing to the LOAD path goes away when we're a real gem.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/executor'

# Test the Executor class.
class TestExecutor < MiniTest::Unit::TestCase
  include NagiosHerald::Util

  # initial setup before we execute tests
  def setup
    @executor = NagiosHerald::Executor.new
    @options = {}
    @options[:env] = File.join(File.dirname(__FILE__), '..', 'env_files', 'nagios_vars.EXAMPLE')
  end

  # We expect a NagiosHerald::Executor object.
  def test_new_executor
    assert_instance_of NagiosHerald::Executor, @executor
  end

  # Make sure we can load an environment file and read some env variables.
  # We'll use Util::get_nagios_var just like Executor does.
  def test_load_env_file
    @executor.load_env_from_file(@options[:env])
    assert_equal "ops@example.com", get_nagios_var('NAGIOS_CONTACTEMAIL')
    assert_equal "PROBLEM",  get_nagios_var('NAGIOS_NOTIFICATIONTYPE')
  end

end
