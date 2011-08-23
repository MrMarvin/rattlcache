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
          ret = {:status => 200,
                 :object => object,
                 :lastModified => mtime,
                 :header => Base64.strict_decode64(firstline.chomp)
          }
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

      def delete(object_key)
        begin
          File.delete(@prefix+object_key)
        rescue Errno::ENOENT

        end
      end

      def open_file(objectKey,how="r")
        begin
          make_shure_dir_exists()
          File.open(@prefix+objectKey,how)
        rescue
          # raise this to the caller
          raise
        end
      end

      def make_shure_dir_exists()
        Dir.mkdir(@prefix) unless File.directory?(@prefix)
      end

    end
  end
end
