require 'nagios-herald'
require 'nagios-herald/formatters/check_disk'
require 'test/unit'
require 'mocha/test_unit'
require 'ostruct'
require 'mock_email_message'
require 'assertions'

class CheckDiskFormatterTest < Test::Unit::TestCase

  NAGIOS_VARS = {

    :HOSTNAME               => "test.host.com",
    :LONGDATETIME           => "Thu May 11 11:11:11 UTC 2011",
    :NOTIFICATIONNUMBER     => "1",
    :NOTIFICATIONRECIPIENTS => "testuser",

    :SERVICEDESC            => "TestService",

    :SERVICEACKAUTHOR       => "service on call",
    :HOSTACKAUTHOR          => "host on call",

    :SERVICEATTEMPT         => "4",
    :HOSTATTEMPT            => "3",

    :SERVICEACKCOMMENT      => "service comment",
    :HOSTACKCOMMENT         => "host comment",

    :SERVICEDURATION        => "0d 0h 5m 11s",
    :HOSTDURATION           => "0d 0h 10m 11s",

    :SERVICENOTES           => "note for service",
    :HOSTNOTES              => "note for host",

    :SERVICEOUTPUT          => "short service output",
    :HOSTOUTPUT             => "short host output",

    :SERVICESTATE           => "S_TESTING",
    :HOSTSTATE              => "H_TESTING",

    :SERVICENOTESURL        => "service_url",
    :HOSTNOTESURL           => "host_url",

    :LASTSERVICESTATE       => "LAST_S_TESTING",
    :LASTHOSTSTATE          => "LAST_H_TESTING",

    :LONGSERVICEOUTPUT      => "long service output",
    :LONGHOSTOUTPUT         => "long host output",

    :MAXSERVICEATTEMPTS     => "4",
    :MAXHOSTATTEMPTS        => "3",

    # The below vars are not available to nagios-herald from the env,
    # but should be generated in the email.
    :SERVICE_ACK_URL        => "http://test/nagios/?cmd_typ=34&host=test.host.com&service=TestService",
    :HOST_ACK_URL           => "http://test/nagios/?cmd_typ=33&host=test.host.com"
  }


  def setup
    @options = OpenStruct.new
    @options.config_file = File.expand_path(File.dirname(__FILE__) + '/../../etc/config.yml.example')
    @options.pager_mode = false
    @options.noemail = false
    @options.debug = false
    @options.nagiosurl = 'http://test/nagios/'


    config = {
      'splunk' => {
        'url'      => 'https://splunk.example.com:8089/services/search/jobs',
        'username' => 'user',
        'password' => 'pwd',
      }
    }
    @cfgmgr = NagiosHerald::ConfigurationManager.get_configuration_manager('simple', config)

    resetEnv
  end

  def resetEnv
    # Load the env with empty strings
    NAGIOS_VARS.each do |k,v|
      ENV["NAGIOS_#{k}"] = ""
    end
  end

  def loadEnv(notification_type, expected_vars)
    # Load the env with the nagios var we want
    all_vars = NAGIOS_VARS
    all_vars[:NOTIFICATIONTYPE] = notification_type

    # Load all the new values
    expected_vars.each do |var|
      val = all_vars.fetch(var)
      ENV["NAGIOS_#{var}"] = val
    end
  end

  def checkEmailIncludeCriticalString(notification_type, expected_string, check_subject = false)
    formatter = NagiosHerald::Formatter::CheckDisk.new(@cfgmgr, @options)
    handler = NagiosHerald::Engine.new(formatter, @options)
    email = MockEmailMessage.new("test@etsy.com")

    handler.report(email, notification_type)
    if check_subject
      assert_contains expected_string, email.subject, "Failed to report #{expected_string} in text email"
    else
      assert_contains expected_string, email.text, "Failed to report #{expected_string} in text email"
      assert_contains expected_string, email.html, "Failed to report #{expected_string} in html email"
    end
    assert_equal(true, email.sent, "Failed to send email")
  end

  def testProblemServiceEmailBody
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :SERVICE_ACK_URL
    ]

    alert_frequency = {
        :period   => "7 days",
        :service  => "service",
        :hostname => "hostname",
        :events_count => {"WARNING" => 17}
    }
    loadEnv('PROBLEM', expected_vars)

    NagiosHerald::Helpers::SplunkReporter.any_instance.stubs(:get_alert_frequency).returns(alert_frequency)
    expected_string = "HOST 'test.host.com' has experienced 17 WARNING alerts in the last 7 days."
    checkEmailIncludeCriticalString('PROBLEM', expected_string)
  end

end
