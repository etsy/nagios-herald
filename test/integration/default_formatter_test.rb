require 'nagios-herald'
require 'nagios-herald/test_helpers/base_test_case'
require 'test/unit'
require 'mocha/test_unit'

class DefaultFormatterTest < NagiosHerald::TestHelpers::BaseTestCase

  def setup
    @cfgmgr = NagiosHerald::ConfigurationManager.get_configuration_manager('simple', {})
    @options = simple_options
    clear_env
  end

  def check_email_include_critical_info(notification_type, expected_vars, check_subject = false)
    load_env(notification_type, expected_vars)
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
