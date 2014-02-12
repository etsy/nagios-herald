require 'net/http'
require 'uri'

# TODO: don't assume the MIME type is image/png; provide a mechanism for ensuring a standard image size
module NagiosHerald
  module Helpers
    class UrlImage
      def self.get_image( uri )
        graph = Net::HTTP.get( URI.parse( uri ) )
      end

      def self.write_image( file_name, content )
        File.delete( file_name ) if File.exists?( file_name )   # remove any pre-existing versions
        written_size = File.open( file_name, 'w' ) { |f| f.write( content ) }
        if written_size == content.size
          return written_size > 0
        else
          false   # oops...
        end
      end

      def self.convert_uri(uri)
        converted_uri = uri.gsub("http:\/\/", "")
        converted_uri.gsub!(/(\/|=|\?|&)/, "_")     # such a hack...
        converted_uri.gsub!(/_+/, "_")              # de-dupe underscores
        return converted_uri
      end

      def self.download_image(uri, path)
        graph = get_image( uri )
        # only push the image path into the array if we successfully create it
        write_image( path, graph ) ? path : nil
      end

      def self.download_images( uris, path )
        path = path.sub(/\/$/, "")   # strip the trailing slash (if it exists) so the components of image_name are clear
        image_paths = []
        uris.each do |uri|
          converted_uri = convert_uri(uri)
          image_path = "#{path}/#{converted_uri}.png"
          # only push the image path into the array if we successfully create it
          image_paths.push(image_path) if download_image(uri, image_path)
        end
        image_paths
      end
    end
  end
end