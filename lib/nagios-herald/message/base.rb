require 'app_conf'
require 'tmpdir'
require 'nagios-herald/logging'
require 'nagios-herald/util'

module NagiosHerald
  class Message
    include NagiosHerald::Logging
    include NagiosHerald::Util

    attr_accessor :body
    attr_accessor :recipients

    def initialize(recipients, options)
      @body       = ""
      @nosend      = options[:nosend]
      @recipients = recipients
    end

    # override #send in the message subclass
    def send
      raise Exception, "#{self.to_s}: You must override #send"
    end

  end
end
