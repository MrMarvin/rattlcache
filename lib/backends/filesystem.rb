require 'json'
require 'base64'

module Rattlecache
  module Backend
    class Filesystem < Cache

      def initialize(prefix = "/tmp/rattlecache/")
        @prefix = prefix
      end

      def get(objectKey)
        #puts "Filesystem gets you: #{objectKey}"
        # get the file from the filesystem
        ret = {:status => 404, :lastModified => nil, :object => nil}
        begin
          f = open_file(objectKey)
          firstline = f.first
          object = f.read
          mtime = f.mtime
          f.close
          
          unless needs_request?(Base64.strict_decode64(firstline.chomp),mtime)
            # If the file needs to be re-requested, simply return 404.
            # note: the first line is encoded in strict base64, so there are no \n's in it.
            # However, reading it from file comes with a CLRF at the end of the line,
            # which the strict_decode doesnt like. Chomp it!
            ret = {:status => 200, :object => object}
          end
        rescue Errno::ENOENT
        end
        return ret
      end

      def post(object)
        # put the file to the filesysten
        firstline = Base64.strict_encode64(object[:header].to_json)
        #puts "Debug: putting headers as firstline: #{firstline}"
        f = open_file(object[:key],"w")
        f.puts(firstline)
        f.puts(object[:data])
        f.close
        #puts "Debug: filesystem posted #{object[:key]}"
      end

      def open_file(objectKey,how="r")
        begin
          Dir.mkdir(@prefix) unless File.directory?(@prefix)
          File.open(@prefix+objectKey,how)
        rescue
          # raise this to the caller
          raise
        end
      end

    end
  end
end
