require 'test/unit'

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
module NagiosHerald
  module TestHelpers
    class BaseTestCase < Test::Unit::TestCase
      def load_env(notification_type, expected_vars)
        # Load the env with the nagios var we want
        all_vars = NAGIOS_VARS
        all_vars[:NOTIFICATIONTYPE] = notification_type
        
        # Load all the new values
        expected_vars.each do |var|
          val = all_vars.fetch(var)
          ENV["NAGIOS_#{var}"] = val
        end
      end
      
      def clear_env
        # Load the env with empty strings
        NAGIOS_VARS.each do |k,_|
          ENV["NAGIOS_#{k}"] = ""
        end
      end
    end
  end
end
