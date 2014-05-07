require 'nagios-herald/message_loader'
require 'nagios-herald/logging'
require 'nagios-herald/util'

# Message objects know best about how to generate and send messages
# The Base class defines @content and @recipients variables as all messages probably
# have some notion of these constructs.
module NagiosHerald
  class Message
    include NagiosHerald::Logging
    include NagiosHerald::Util

    attr_accessor :content
    attr_accessor :recipients

    def initialize(recipients, options)
      @nosend     = options[:nosend]
      # TODO: instead of passing this in via the subclass, let's set it via message.recipients
      @recipients = recipients
    end

    # Public: Defines what is required to send a message.
    # The message type knows best how this is done. Override the #send method
    # in your message subclass.
    def send
      raise Exception, "#{self.to_s}: You must override #send"
    end

    def self.message_types
      @@message_types ||= {}
    end

    # Public: When subclassed message types are instantiated, add them to the @@message_types hash.
    # The key is the downcased and snake_cased name of the class file (i.e. email);
    # the value is the actual class (i.e. Email) so that we can easily
    # instantiate message types when we know the message type name.
    # Learned this pattern thanks to the folks at Chef and @jonlives.
    # See https://github.com/opscode/chef/blob/11-stable/lib/chef/knife.rb#L79#L83
    #
    # Returns the message_types hash.
    def self.inherited(subclass)
      subclass_base_name = subclass.name.split('::').last
      if subclass_base_name == subclass_base_name.upcase
        # we've got an all upper case class name (probably an acronym like IRC); just downcase the whole thing
        subclass_base_name.downcase!
        message_types[subclass_base_name] = subclass
      else
        subclass_base_name.gsub!(/[A-Z]/) { |s| "_" + s } # replace uppercase with underscore and lowercase
        subclass_base_name.downcase!
        subclass_base_name.sub!(/^_/, "")   # strip the leading underscore
        message_types[subclass_base_name] = subclass
      end
    end

  end
end
