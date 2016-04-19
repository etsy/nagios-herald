require 'nagios-herald/helper_loader'
require 'nagios-herald/logging'
require 'nagios-herald/util'

# The helper base currently only defines helper_types.
module NagiosHerald
  class Helper
    include NagiosHerald::Logging
    include NagiosHerald::Util

    def initialize
      return true
    end

    def self.helper_types
      @@helper_types ||= {}
    end

    # Public: When subclassed helper types are instantiated, add them to the @@helper_types hash.
    # The key is the downcased and snake_cased name of the class file (i.e. email);
    # the value is the actual class (i.e. Email) so that we can easily
    # instantiate helper types when we know the helper type name.
    # Learned this pattern thanks to the folks at Chef and @jonlives.
    # See https://github.com/opscode/chef/blob/11-stable/lib/chef/knife.rb#L79#L83
    #
    # Returns the helper_types hash.
    def self.inherited(subclass)
      subclass_base_name = subclass.name.split('::').last
      if subclass_base_name == subclass_base_name.upcase
        # we've got an all upper case class name (probably an acronym like IRC); just downcase the whole thing
        subclass_base_name.downcase!
        helper_types[subclass_base_name] = subclass
      else
        subclass_base_name.gsub!(/[A-Z]/) { |s| "_" + s } # replace uppercase with underscore and lowercase
        subclass_base_name.downcase!
        subclass_base_name.sub!(/^_/, "")   # strip the leading underscore
        helper_types[subclass_base_name] = subclass
      end
    end

  end
end
