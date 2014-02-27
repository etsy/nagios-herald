require 'nagios-herald'
# I'm pretty sure these requires could be better
require 'nagios-herald/configuration_manager/chef'
require 'nagios-herald/configuration_manager/simple'
require 'test/unit'

class ConfigurationManagerTestCase < Test::Unit::TestCase
  def setup
    @managers = [
                NagiosHerald::ConfigurationManager::ChefManager.new(nil),
                NagiosHerald::ConfigurationManager::SimpleManager.new(nil),
               ]
  end
  def test_configuration_managers_respond_to_api
    required_methods = [
                        :get_cluster_name_for_host,
                       ]
    @managers.each {|manager|
      required_methods.each { |method| 
        assert manager.respond_to?(method)
      }
    }
  end
end
