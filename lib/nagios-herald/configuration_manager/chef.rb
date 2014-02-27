require File.expand_path(File.join(File.dirname(__FILE__), 'base'))
require 'chef/search/query'

module NagiosHerald
  module ConfigurationManager
    class ChefManager < BaseManager
      def load_config
        return @config_loaded unless @config_loaded.nil?
        config_file = self.get('knife_config') || '~/.chef/knife.rb'
        config_file = File.expand_path(config_file)
        if !File.exist?(config_file)
          $stderr.puts "Knife config file not found (#{config_file})"
          @config_loaded = false
        else
          Chef::Config.from_file(config_file)
          @config_loaded = true
        end
        @config_loaded
      end

      def get_cluster_name_for_host(host)
        return nil unless load_config
        query = Chef::Search::Query.new
        # we're only expecting a single node to be returned --> make sure it's the case!
        node = query.search('node', "fqdn:#{host}").first.first
        node.ganglia.cluster_name
      end
    end
  end
end
