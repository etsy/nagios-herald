require 'chef/search/query'

module NagiosHerald
  module Helpers
    class GangliaGraph
      include NagiosHerald::Logging

      # Public: Initialize a GangliaGraph helper object.
      #
      # Returns GangliaGraph helper object.
      def initialize
        @ganglia_base_uri = Config.config['servers']['ganglia']
      end

      # Public: Loads a Chef knife config.
      # I recognize not everyone uses Chef, or any CM for that matter.
      # Still, I like having this example here.
      #
      # Returns true/false depending on whether a Chef knife config was loaded.
      def load_knife_config
        return @knife_config_loaded unless @knife_config_loaded.nil?

        knife_config_file = Config.config['knife_config'] ? Config.config['knife_config'] : '~/.chef/knife.rb'
        knife_config_file = File.expand_path(knife_config_file)
        if !File.exist?(knife_config_file)
          $stderr.puts "Knife config file not found (#{knife_config_file})"
          @knife_config_loaded = false
        else
          Chef::Config.from_file(knife_config_file)
          @knife_config_loaded = true
        end
        @knife_config_loaded
      end

      # Public: Get the Ganglia cluster name for a given host.
      # So, if you're still reading this *and* you use Chef,
      # I recognize that you may not store the Ganglia cluster name as a node
      # attribute. If you do, it's probably not called 'cluster_name'...
      #
      # host - The name of the host whose Ganglia cluster name we need to look up.
      #
      # Returns the Ganglia cluster name for the host.
      def get_cluster_name_for_host(host)
        return nil unless load_knife_config
        query = Chef::Search::Query.new
        # we're only expecting a single node to be returned --> make sure it's the case!
        chef_node = query.search('node', "fqdn:#{host}").first.first
        chef_node.ganglia.cluster_name
      end

      # Public: Generate the URL required to download a graph of the require metric
      #
      # cluster_name - The Ganglia cluster this node belongs to.
      # host - The hostname of the node we need a metric for.
      # metric - The name of the Ganglia metric we need.
      # range - The time period we expect the metric to cover.
      #
      # Example
      #
      #   get_ganglia_url("Web", "web0001.example.com", "part_max_used", "1day")
      #
      # Returns a full Ganglia URL defining the metric graph to download
      def get_ganglia_url(cluster_name, host, metric, range)
        return "http://#{@ganglia_base_uri}/graph.php?&c=#{cluster_name}&h=#{host}&m=#{metric}&r=#{range}&z=medium"
      end

      # Public: Retrieve the Ganglia graphs we desire
      #
      # hosts - An array of hosts for which to retrieve metrics.
      # metric - The name of the Ganglia metric we need.
      # path - The local path on the host running nagios-herald under which image
      #        files will be temporarily generated.
      # range - The time period we expect the metric to cover.
      #
      # Example
      #
      #   get_graphs([web0001.example.com], "part_max_used", "/tmp/img1234", "1day")
      #
      # Returns the local paths of all downloaded images to be attached/inlined with a message.
      def get_graphs( hosts, metric, path, range )
        # strip the trailing slash (if it exists) so the components of image_name are clear
        path = path.sub(/\/$/, "")
        image_paths = []
        hosts.each do |host|
          cluster_name = get_cluster_name_for_host(host)
          url = get_ganglia_url(cluster_name, host, metric, range)
          image_path = "#{path}/#{host}-#{metric}.png"
          success = NagiosHerald::Helpers::UrlImage.download_image(url, image_path)
          if success
            image_paths.push( image_path )
          else
            logger.warn("No Ganglia graph found for '#{host}' (cluster: '#{cluster_name}') - '#{metric}' in '#{range}'")
          end
        end
        return image_paths
      end
    end
  end
end
