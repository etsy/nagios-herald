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
    email = NagiosHerald::EmailMessage.new("test@etsy.com")
    email.expects(:send).once
    handler.report(email, notification_type)

    expected_vars.each do |var|
      if var == :NOTIFICATIONTYPE
        val = notification_type
      else
        val = NAGIOS_VARS.fetch(var)
      end
      if check_subject
        assert_includes email.subject, val, "Failed to report #{var} in text email"
      else
        assert_includes email.text, val, "Failed to report #{var} in text email"
        assert_includes email.html, val, "Failed to report #{var} in html email"
      end
    end
  end

  def test_service_email_subject
    expected_vars = [:HOSTNAME, :NOTIFICATIONTYPE, :SERVICEDESC, :SERVICESTATE]

    ["PROBLEM", "FLAPPINGSTART","RECOVERY","FLAPPINGSTOP","ACKNOWLEDGEMENT"].each do |notification_type|
      check_email_include_critical_info(notification_type, expected_vars, true)
    end
  end

  def test_host_email_subject
    expected_vars = [:HOSTNAME, :NOTIFICATIONTYPE, :HOSTSTATE]

    ["PROBLEM", "FLAPPINGSTART","RECOVERY","FLAPPINGSTOP","ACKNOWLEDGEMENT"].each do |notification_type|
      check_email_include_critical_info(notification_type, expected_vars, true)
    end

  end

  def test_problem_service_email_body
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :SERVICE_ACK_URL
    ]

    check_email_include_critical_info('PROBLEM', expected_vars)
  end

  def test_flapping_start_service_email_body
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :SERVICE_ACK_URL
    ]
    check_email_include_critical_info('FLAPPINGSTART', expected_vars)
  end

  def test_problem_host_email_body
    expected_vars = [
      :HOSTNAME,
      :HOSTSTATE, :HOSTDURATION, :LASTHOSTSTATE, :HOSTATTEMPT, :MAXHOSTATTEMPTS,
      :HOSTOUTPUT,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :HOST_ACK_URL
    ]
    check_email_include_critical_info('PROBLEM', expected_vars)
  end

  def test_flapping_start_host_email_body
    expected_vars = [
      :HOSTNAME,
      :HOSTSTATE, :HOSTDURATION, :LASTHOSTSTATE, :HOSTATTEMPT, :MAXHOSTATTEMPTS,
      :HOSTOUTPUT,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :HOST_ACK_URL
    ]
    check_email_include_critical_info('FLAPPINGSTART', expected_vars)
  end

  def test_recovery_service_email_body
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :LONGDATETIME, :NOTIFICATIONNUMBER
    ]
    check_email_include_critical_info('RECOVERY', expected_vars)
  end

  def test_recovery_flapping_stop_email_body
    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :SERVICESTATE, :SERVICEDURATION, :LASTSERVICESTATE, :SERVICEATTEMPT, :MAXSERVICEATTEMPTS,
      :SERVICEOUTPUT, :LONGSERVICEOUTPUT, :SERVICENOTES, :SERVICENOTESURL,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :LONGDATETIME, :NOTIFICATIONNUMBER
    ]
    check_email_include_critical_info('FLAPPINGSTOP', expected_vars)
  end

  def test_recovery_host_email_body
    expected_vars = [
      :HOSTNAME,
      :HOSTSTATE, :HOSTDURATION, :LASTHOSTSTATE, :HOSTATTEMPT, :MAXHOSTATTEMPTS,
      :HOSTOUTPUT,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :LONGDATETIME, :NOTIFICATIONNUMBER
    ]
    check_email_include_critical_info('RECOVERY', expected_vars)
  end

  def test_flapping_stop_host_email_body
    expected_vars = [
      :HOSTNAME,
      :HOSTSTATE, :HOSTDURATION, :LASTHOSTSTATE, :HOSTATTEMPT, :MAXHOSTATTEMPTS,
      :HOSTOUTPUT,
      :NOTIFICATIONRECIPIENTS, :LONGDATETIME, :NOTIFICATIONNUMBER,
      :LONGDATETIME, :NOTIFICATIONNUMBER
    ]
    check_email_include_critical_info('FLAPPINGSTOP', expected_vars)
  end

  def test_acknowledgment_service_email_body
    # manually add servicestate in the env since it's not present in the email
    # but needs to be present in the env
    ENV["NAGIOS_SERVICESTATE"] = 'ACKNOWLEDGEMENT'

    expected_vars = [
      :HOSTNAME, :SERVICEDESC,
      :LONGDATETIME, :SERVICEACKAUTHOR, :SERVICEACKCOMMENT
    ]

    check_email_include_critical_info('ACKNOWLEDGEMENT', expected_vars)
  end

  def test_acknowledgment_host_email_body
    # manually add servicestate in the env since it's not present in the email
    # but needs to be present in the env
    ENV["NAGIOS_HOSTSTATE"] = 'ACKNOWLEDGEMENT'

    expected_vars = [
      :HOSTNAME,
      :LONGDATETIME, :HOSTACKAUTHOR, :HOSTACKCOMMENT
    ]

    check_email_include_critical_info('ACKNOWLEDGEMENT', expected_vars)
  end


  def test_problem_service_pager_body
    @options.pager_mode = true

    expected_vars = []
    check_email_include_critical_info('PROBLEM', expected_vars)
  end
end
