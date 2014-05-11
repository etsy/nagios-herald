require 'net/http'
require 'uri'

# TODO: don't assume the MIME type is image/png; provide a mechanism for ensuring a standard image size
module NagiosHerald
  module Helpers
    class UrlImage

      # Public: Requests an image by its URI.
      #
      # uri - The URI of the image resource.
      #
      # Returns the content of the image.
      def self.get_image( uri )
        graph = Net::HTTP.get( URI.parse( uri ) )
      end

      # Public: Writes te given content to a file name.
      #
      # file_name - The name of the file to write.
      # content - Arbitrary content to write into the file.
      #
      # Returns true if successful, false otherwise.
      def self.write_image( file_name, content )
        File.delete( file_name ) if File.exists?( file_name )   # remove any pre-existing versions
        written_size = File.open( file_name, 'w' ) { |f| f.write( content ) }
        if written_size == content.size
          return written_size > 0   # why aren't we just returning true?
        else
          false   # oops...
        end
      end

      # Public: Convert the URI to a useful name to be used in the image file name.
      # Removes the transport type and query characters.
      #
      # uri - The URI to be converted.
      #
      # Returns the converted URI.
      # FIXME: This doesn't account for HTTPS URIs.
      def self.convert_uri(uri)
        converted_uri = uri.gsub("http:\/\/", "")
        converted_uri.gsub!(/(\/|=|\?|&)/, "_")     # such a hack...
        converted_uri.gsub!(/_+/, "_")              # de-dupe underscores
        return converted_uri
      end

      # Public: Downloads an image and writes it to a file.
      #
      # uri - The URI of the image resource.
      # path - The destination file for the image content.
      #
      # Returns nothing.
      def self.download_image(uri, path)
        graph = get_image( uri )
        # only push the image path into the array if we successfully create it
        write_image( path, graph ) ? path : nil
      end

      # To be honest, I don't recall this method's purpose.
      # It's only called in the ``bin/get_graph`` script. May be dead code.
      # TODO: Determine if this is still necessary.
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
