require 'nagios-herald'
require 'test/unit'
require 'ostruct'
require 'mock_email_message'
require 'assertions'

class DefaultFormatterTest < Test::Unit::TestCase

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

    @cfgmgr = NagiosHerald::ConfigurationManager.get_configuration_manager('simple', {})

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

  def checkEmailIncludeCriticalInfo(notification_type, expected_vars, check_subject = false)
    loadEnv(notification_type, expected_vars)
    formatter = NagiosHerald::Formatter::DefaultFormatter.new(@cfgmgr, @options)
    handler = NagiosHerald::Engine.new(formatter, @options)
    email = MockEmailMessage.new("test@etsy.com")

    handler.report(email, notification_type)

    expected_vars.each do |var|
      if var == :NOTIFICATIONTYPE
        val = notification_type
      else
        val = NAGIOS_VARS.fetch(var)
      end
      if check_subject
        assert_contains val, email.subject, "Failed to report #{var} in text email"
      else
        assert_contains val, email.text, "Failed to report #{var} in text email"
        assert_contains val, email.html, "Failed to report #{var} in html email"
      end
      assert_equal(true, email.sent, "Failed to send email")
    end
  end

  def testServiceEmailSubject
    expected_vars = [:HOSTNAME, :NOTIFICATIONTYPE, :SERVICEDESC, :SERVICESTATE]

    ["PROBLEM", "FLAPPINGSTART","RECOVERY","FLAPPINGSTOP","ACKNOWLEDGEMENT"].each do |notification_type|
      checkEmailIncludeCriticalInfo(notification_type, expected_vars, true)
    end
  end

  def testHostEmailSubject
    expected_vars = [:HOSTNAME, :NOTIFICATIONTYPE, :HOSTSTATE]

    ["PROBLEM", "FLAPPINGSTART","RECOVERY","FLAPPINGSTOP","ACKNOWLEDGEMENT"].each do |notification_type|
      checkEmailIncludeCriticalInfo(notification_type, expected_vars, true)
    end
  end

  def testProblemServiceEmailBody
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :SERVICE_ACK_URL
    ]

    checkEmailIncludeCriticalInfo('PROBLEM', expected_vars)
  end

  def testFlappingStartServiceEmailBody
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :SERVICE_ACK_URL
    ]
    checkEmailIncludeCriticalInfo('FLAPPINGSTART', expected_vars)
  end

  def testProblemHostEmailBody
    expected_vars = [
      :HOSTNAME,
      :HOSTSTATE, :HOSTDURATION, :LASTHOSTSTATE, :HOSTATTEMPT, :MAXHOSTATTEMPTS,
      :HOSTOUTPUT,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :HOST_ACK_URL
    ]
    checkEmailIncludeCriticalInfo('PROBLEM', expected_vars)
  end

  def testFlappingStartHostEmailBody
    expected_vars = [
      :HOSTNAME,
      :HOSTSTATE, :HOSTDURATION, :LASTHOSTSTATE, :HOSTATTEMPT, :MAXHOSTATTEMPTS,
      :HOSTOUTPUT,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :HOST_ACK_URL
    ]
    checkEmailIncludeCriticalInfo('FLAPPINGSTART', expected_vars)
  end

  def testRecoveryServiceEmailBody
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :LONGDATETIME, :NOTIFICATIONNUMBER
    ]
    checkEmailIncludeCriticalInfo('RECOVERY', expected_vars)
  end

  def testRecoveryFlappingStopEmailBody
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :LONGDATETIME, :NOTIFICATIONNUMBER
    ]
    checkEmailIncludeCriticalInfo('FLAPPINGSTOP', expected_vars)
  end

  def testRecoveryHostEmailBody
    expected_vars = [
      :HOSTNAME,
      :HOSTSTATE, :HOSTDURATION, :LASTHOSTSTATE, :HOSTATTEMPT, :MAXHOSTATTEMPTS,
      :HOSTOUTPUT,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :LONGDATETIME, :NOTIFICATIONNUMBER
    ]
    checkEmailIncludeCriticalInfo('RECOVERY', expected_vars)
  end

  def testFlappingStopHostEmailBody
    expected_vars = [
      :HOSTNAME,
      :HOSTSTATE, :HOSTDURATION, :LASTHOSTSTATE, :HOSTATTEMPT, :MAXHOSTATTEMPTS,
      :HOSTOUTPUT,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :LONGDATETIME, :NOTIFICATIONNUMBER
    ]
    checkEmailIncludeCriticalInfo('FLAPPINGSTOP', expected_vars)
  end

  def testAcknowledgmentServiceEmailBody
    # manually add servicestate in the env since it's not present in the email
    # but needs to be present in the env
    ENV["NAGIOS_SERVICESTATE"] = 'ACKNOWLEDGEMENT'

    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :LONGDATETIME, :SERVICEACKAUTHOR, :SERVICEACKCOMMENT
    ]

    checkEmailIncludeCriticalInfo('ACKNOWLEDGEMENT', expected_vars)
  end

  def testAcknowledgmentHostEmailBody
    # manually add servicestate in the env since it's not present in the email
    # but needs to be present in the env
    ENV["NAGIOS_HOSTSTATE"] = 'ACKNOWLEDGEMENT'

    expected_vars = [
      :HOSTNAME,
      :LONGDATETIME, :HOSTACKAUTHOR, :HOSTACKCOMMENT
    ]

    checkEmailIncludeCriticalInfo('ACKNOWLEDGEMENT', expected_vars)
  end


  def testProblemServicePagerBody
    @options.pager_mode = true

    expected_vars = []
    checkEmailIncludeCriticalInfo('PROBLEM', expected_vars)
  end
end
