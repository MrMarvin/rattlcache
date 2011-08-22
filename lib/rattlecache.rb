require 'backend_manager'
require 'net/http'
require 'digest/sha2'

module Rattlecache

  class Cache

    # @param backend [Symbol]
    def initialize(backend = :filesystem)
      @backend = Rattlecache::Backend.fetch(backend)
    end

    @request_pragmas = {
      "guild" => "Check if any fields are requested. If yes, request without fields and look into ['lastModified'] if we need to fetch new or answer with out cached result.",
      "data" => "Everything data related should be considered stable. Cache it for one week.",
      "auction" => "dont know yet...",
      "else" => "cache it for as long as 'RETRY-AFTER'-responseheader told us. (600 sec)"
    }

    # @param objectKey [String]
    def get(objectKey)
      #puts "Cache class gets you: #{objectKey}"
      @backend.get(sanitize(objectKey))
    end

    # @param object [Hash]
    def post(object)
      #puts "Cache class puts: #{object[:key]}"
      @backend.post({:key => sanitize(object[:key]), :header => object[:header], :data => object[:data]})
    end

    # @param headerline [Hash]
    # @param mtime [Time]
    # @return [TrueClass|FalseClass]
    def needs_request?(headerline,mtime)
      header = JSON.parse(headerline)
      #header["date"][0] is a String with CGI.rfc1123_date() encoded time,
      # as there is no easy method to inverse this coding, I will keep using the files mtime
      # to estimate when the data was last recieved.
      unless header["retry-after"].nil?
        mtime+(header["retry-after"][0].to_i) < Time.now()
      else
        # stupid manual seconds to week multiply
        mtime+(60*60*24*7) < Time.now()
      end
    end

    # @param objectKey [String]
    # @return [String]
    def sanitize(objectKey)
      # strip scheme, sort paramters and encode for safty
      urlObj = URI.parse(objectKey)
      key = urlObj.host
      key << urlObj.path
      key << sort_params(urlObj.query)
      Digest::SHA256.hexdigest(key)
    end

    # @param query [String]
    # @return [String]
    def sort_params(query)
      q = Hash.new
      query.split("&").each do |parampair|
        q[parampair.split("=")[0]] = parampair.split("=")[1]
      end
      s = Array.new
      q.sort.each { |pair| s << pair.join("=")}
      "?"+s.join("&")
    end

    # @param objectKey [String]
    # @return [String]
    def request_type(objectKey)
      URI.parse(objectKey).path.split("/")[1]
    end

    # @param query [String]
    # @return [TrueClass|FalseClass]
    def has_fields?(query)
      not query.scan(/fields=/).empty?
    end

  end
end
