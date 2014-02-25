require File.expand_path(File.join(File.dirname(__FILE__), 'base'))

module NagiosHerald
  module ConfigurationManager
    class SimpleManager < AbstractConfigurationManager
      def get_cluster_name_for_host(host)
        host
      end
    end
  end
end
