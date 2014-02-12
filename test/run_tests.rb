$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'nagios-herald'
require File.expand_path(File.dirname(__FILE__) + "/assertions")
require File.expand_path(File.dirname(__FILE__) + "/mock_email_message")
require File.expand_path(File.dirname(__FILE__) + '/integration/default_formatter_test')
