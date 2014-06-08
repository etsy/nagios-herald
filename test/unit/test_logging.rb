require 'minitest/autorun'

# I assume cat'ing to the LOAD path goes away when we're a real gem.
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'nagios-herald'
require 'nagios-herald/config'
require 'nagios-herald/logging'

# Test the Config module.
class TestLogging < MiniTest::Unit::TestCase
  include NagiosHerald::Logging

  # Initial setup before we execute tests
  def setup
    @options = {}
    @options['config_file'] = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'etc', 'config.yml.example'))
    @tmp_logfile = '/tmp/nagios-herald-logging.log'
    # Specify a log file
    @options['logfile'] = @tmp_logfile
    # Load the config
    NagiosHerald::Config.load(@options)
  end

  def test_info_message
    #INFO -- test_logging.rb (TestLogging): Testing nagios-herald logging
    logger.info "Testing nagios-herald logging"
    @log_message = File.new(@tmp_logfile, 'r').read
    assert_match /INFO.+Testing nagios-herald logging/, @log_message
  end

  def teardown
    File.delete(@tmp_logfile)
  end

end
