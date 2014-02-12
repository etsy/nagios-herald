module NagiosHerald
  module Helpers
    class GangliaGraph
      include NagiosHerald::Logging

      def initialize(cfgmgr, ganglia_url)
        @cfgmgr = cfgmgr
        @ganglia_url  = ganglia_url
      end

      def get_ganglia_url(cluster_name, host, metric, range)
        return "http://#{@ganglia_url}/graph.php?&c=#{cluster_name}&h=#{host}&m=#{metric}&r=#{range}&z=medium"
      end

      def get_graphs( hosts, metric, path, range )
        # strip the trailing slash (if it exists) so the components of image_name are clear
        path = path.sub(/\/$/, "")
        image_paths = []
        hosts.each do |host|
          cluster_name = @cfgmgr.get_cluster_name_for_host( host )
          uri = get_ganglia_url(cluster_name, host, metric, range)
          image_path = "#{path}/#{host}-#{metric}.png"
          success = NagiosHerald::Helpers::UrlImage.download_image(uri, image_path)
          if success
            image_paths.push( image_path )
          else
            logger.warn("No ganglia graph found for '#{host}' (cluster: '#{cluster_name}')- '#{metric}' in '#{range}'")
          end
        end
        return image_paths
      end
    end
  end
end
