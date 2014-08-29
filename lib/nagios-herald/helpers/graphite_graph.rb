require 'securerandom'
require 'uri'

module NagiosHerald
  module Helpers
    class GraphiteGraph
      include NagiosHerald::Logging

      # Public: Initialize a GraphiteGraph helper object.
      #
      # Returns a GraphiteGraph helper object.
      def initialize
        # Currently hard-codes the value for optional graphs showing historical
        # data.
        @graphite_historical_lookup = '-24h'
        @image_paths = []
      end

      # Public: Download a Graphite image.
      #
      # url - The Graphite url we'll download as an image.
      # download_path - The path to where the image will be downloaded.
      #
      # Returns nothing. Appends the downloaded image path to @image_paths.
      def download_image(url, download_path)
        success = NagiosHerald::Helpers::UrlImage.download_image(url, download_path)
        if success
          @image_paths.push(download_path)
        else
          logger.warn("Could not download Graphite graph for '#{url}'")
        end
      end

      # Public: Retrieve a Graphite graph
      #
      # url - A string containing the full URL to get from Graphite.
      # path - The local path on the host running nagios-herald under which image
      #        files will be temporarily generated.
      # show_historical - A boolean that allows one to optionally download a
      #                   showing historical data for comparison.
      #                   Defaults to false.
      #
      # Because this will probably be fed URLs used in Nagios checks, we'll
      # strip out '&format' and '&rawData' query parameters to ensure we
      # get an image instead of text/json/csv/etc.
      #
      # In cases where the method is called requesting an historical image
      # we'll strip '&until' and replace the value of '&from' with that of
      # @graphite_historical_lookup.
      #
      # Example
      #
      #   get_graph("http://graphite.example.com/render/?target=foo.bar.baz?from=-15min", "/tmp/img1234", true)
      #
      # Returns the local path of the downloaded image to be attached/inlined with a message.
      def get_graph(url, path, show_historical=nil)
        uri = URI(url)
        # Strip &rawData parameter.
        uri.query.gsub!(/&rawData([^&]*)/, '')
        # Strip the &format parameter.
        uri.query.gsub!(/&format([^&])*/, '')
        # Strip the trailing slash from the path.
        path = path.sub(/\/$/, "")
        # Generate a random UUID to be used in the image filename.
        image_uuid = SecureRandom.uuid
        image_path = "#{path}/#{image_uuid}.png"
        image_url = uri.to_s
        download_image(image_url, image_path)
        if show_historical
          historical_image_path = "#{path}/#{image_uuid}#{@graphite_historical_lookup}.png"
          uri.query.gsub!(/from=([^&]*)/, "from=#{@graphite_historical_lookup}")
          historical_url = uri.to_s
          download_image(historical_url, historical_image_path)
        end
        return @image_paths
      end
    end
  end
end
