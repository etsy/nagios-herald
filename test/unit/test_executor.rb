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

  def teardown
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
    assert_equal "PROBLEM", get_nagios_var('NAGIOS_NOTIFICATIONTYPE')
  end

  # Get the file names of each of the formatter classes and confirm they load properly.
  # This helps ensure formatters are named and subclassed properly.
  def test_load_formatters
    formatter_dir = File.join(File.dirname(__FILE__), '..', '..', 'lib', 'nagios-herald', 'formatters')
    formatter_class_files = Dir["#{formatter_dir}/*.rb"]
    @executor.load_formatters
    formatter_class_files.each do |formatter_class_file|
      class_file = File.basename(formatter_class_file, '.rb') # strip the extension
      next if class_file.eql?('base') # base.rb doesn't get loaded
      assert NagiosHerald::Formatter.formatters.has_key?(class_file), "'#{formatter_dir}/#{class_file}.rb' was not loaded. "\
      "Check that it's named and subclassed properly.\n"\
      "See https://github.com/etsy/nagios-herald/blob/master/docs/formatters.md for help."
    end
  end

  # Get the file names of each of the message classes and confirm they load properly.
  # This helps ensure messages are named and subclassed properly.
  def test_load_messages
    message_dir = File.join(File.dirname(__FILE__), '..', '..', 'lib', 'nagios-herald', 'messages')
    message_class_files = Dir["#{message_dir}/*.rb"]
    @executor.load_messages
    message_class_files.each do |message_class_file|
      class_file = File.basename(message_class_file, '.rb') # strip the extension
      next if class_file.eql?('base') # base.rb doesn't get loaded
      assert NagiosHerald::Message.message_types.has_key?(class_file), "'#{message_dir}/#{class_file}.rb' was not loaded. "\
      "Check that it's named and subclassed properly.\n"\
      "See https://github.com/etsy/nagios-herald/blob/master/docs/messages.md for help."
    end
  end

  # Get the file names of each of the helpers and confirm they load properly.
  # This helps ensure helpers are named and subclassed properly.
  def test_load_helpers
    helper_dir = File.join(File.dirname(__FILE__), '..', '..', 'lib', 'nagios-herald', 'helpers')
    helper_class_files = Dir["#{helper_dir}/*.rb"]
    @executor.load_helpers
    helper_class_files.each do |helper_class_file|
      class_file = File.basename(helper_class_file, '.rb') # strip the extension
      next if class_file.eql?('base') # base.rb doesn't get loaded
      assert NagiosHerald::Helper.helper_types.has_key?(class_file), "'#{helper_dir}/#{class_file}.rb' was not loaded. "\
      "Check that it's named and subclassed properly.\n"\
      "See https://github.com/etsy/nagios-herald/blob/master/docs/helpers.md for help.\n
      #{NagiosHerald::Helper.helper_types}"
    end
  end

end
