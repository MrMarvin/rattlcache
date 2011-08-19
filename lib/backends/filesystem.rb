module Rattlecache
  module Backend
    class Filesystem

      def initialize(prefix = "/tmp/rattlecache/")
        @prefix = prefix
      end

      def get(objectKey)
        # get the file from the filesystem
        begin
          f = open_file(objectKey)
          object = f.read
          mtime = f.mtime
          f.close
          {:status => 200, :lastModified => mtime, :object => object}
        rescue Errno::ENOENT
          {:status => 404, :lastModified => nil, :object => nil}
        end
      end

      def post(object)
        # put the file to the filesysten
        f = open_file(object[:key],"w")
        f.puts(object[:data])
        f.close
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
