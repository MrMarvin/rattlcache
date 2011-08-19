require 'backend_manager'
require 'net/http'
require 'digest/sha2'

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
      puts "Cache class puts: #{object[:key]}"
      @backend.post({:key => sanitize(object[:key]),:data => object[:data]})
    end

    def sanitize(objectKey)
      # strip scheme, sort paramters and encode for safty
      urlObj = URI.parse(objectKey)
      key = urlObj.host
      key << urlObj.path
      key << sort_params(urlObj.query)
      Digest::SHA256.hexdigest(key)
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
