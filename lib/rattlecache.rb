require 'backend_manager'
require 'net/http'
require 'base64'

module Rattlecache

  class Cache

    def initialize(backend = :filesystem)
      @backend = Rattlecache::Backend.fetch(backend)
    end

    def get(objectKey)
      puts "Cache class gets you: #{objectKey}"
      @backend.get(sanitize(objectKey))
    end

    def post(object)
      puts "Cache class gets you: #{objectKey}"
      @backend.post({sanitize(object[:key]),object[:data]})
    end

    def sanitize(objectKey)
      # strip scheme, sort paramters and encode URL style
      urlObj = URI.parse(objectKey)
      key = urlObj.host
      key << urlObj.path
      key << sort_params(urlObj.query)
      Base64.encode64(key)
    end

    def sort_params(query)
      q = Hash.new
      query.split("&").each do |parampair|
        q[parampair.split("=")[0]] = parampair.split("=")[1]
      end
      s = Array.new
      q.sort.each { |pair| s << pair.join("=")}
      "?"+s.join("&")
    end

  end
end
