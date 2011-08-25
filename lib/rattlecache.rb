require 'backend_manager'
require 'net/http'
require 'digest/sha2'

module Rattlecache

  class Cache

    # @param backend [Symbol]
    # @param adapter [Battlenet::Adapter::AbstractAdapter]
    def initialize(backend = :filesystem, adapter = nil)
      @adapter = adapter
      @backend = Rattlecache::Backend.fetch(backend)

      @status = Hash.new
      @status[:hits] = 0
      @status[:misses] = 0
      @status[:posts] = 0
    end

    @request_pragmas = {
      "guild" => "Check if any fields are requested. If yes, request without fields and look into ['lastModified'] if we need to fetch new or answer with out cached result.",
      "data" => "Everything data related should be considered stable. Cache it for one week.",
      "auction" => "dont know yet...",
      "else" => "cache it for as long as 'RETRY-AFTER'-responseheader told us. (600 sec)"
    }

    # @param url [String]
    # @param header [Hash]
    def get(url, header = nil)
      @header = header
      @header['User-Agent'] = @header['User-Agent'] << " (with rattlecache)" unless header.nil?
      #puts "Cache class gets you: #{objectKey}"

      # what to do with this request?
      case request_type(url)
        when "guild"
          require 'caches/Fieldsrequestcache'
          res = Rattlecache::Fieldsrequestcache.new(@backend,@adapter).get(url,header)
        when "character"
          require 'caches/Fieldsrequestcache'
          res = Rattlecache::Fieldsrequestcache.new(@backend,@adapter).get(url,header)
        when /auction.*/
          require 'caches/Auctionscache'
          res = Rattlecache::Auctionscache.new(@backend,@adapter).get(url,header)
        when "item"
          # for items it seems reasonable to cache them at least for a week
          # a week in seconds: 60*60*24*7 = 604800
          res = check_and_return(@backend.get(sanitize(url)),604800)
        else
          res =  check_and_return(@backend.get(sanitize(url)))
      end
      if res[:status] == 200
        @status[:hits] +=1
      else
        @status[:misses] +=1
      end
      res
    end

    def check_and_return(backend_result,given_time = nil)
      if given_time.nil?
        if backend_result[:status] == 200 and generic_needs_request?(backend_result[:header],backend_result[:lastModified])
          backend_result = {:status => 404}
        end
      else
        if backend_result[:status] == 200 and needs_request_with_given_time?(given_time,backend_result[:lastModified])
          backend_result = {:status => 404}
        end
      end
      backend_result
    end

    # @param object [Hash]
    def post(object)
      @status[:posts] += 1
      #puts "Cache class puts: #{object[:key]}"
      @backend.post({:key => sanitize(object[:key]), :header => object[:header], :data => object[:data]})
    end

    def delete(url)
      @backend.delete(sanitize(url))
    end

    def flush
      @backend.flush()
    end

    # @param headerline [Hash]
    # @param mtime [Time]
    # @return [TrueClass|FalseClass]
    def generic_needs_request?(headerline,mtime,alternative_living_time = 3600)
      header = JSON.parse(headerline)
      #header["date"][0] is a String with CGI.rfc1123_date() encoded time,
      # as there is no easy method to inverse this coding, I will keep using the files mtime
      # to estimate when the data was last recieved.
      unless header["cache-control"].nil?
        mtime+header["cache-control"][0].split("=")[1].to_i < Time.now()
      else
        unless header["retry-after"].nil?
          mtime+(header["retry-after"][0].to_i) < Time.now()
        else
          # if we dont find any hint, pull it again!
          puts "Warning: Cache couldn't find any hint if this object is still valid!"
          mtime+alternative_living_time < Time.now()
        end
      end
    end

    def needs_request_with_given_time?(given_time,mtime)
      mtime+given_time < Time.now
    end

    # @param objectKey [String]
    # @return [String]
    def sanitize(objectKey)
      # strip scheme, sort paramters and encode for safty
      urlObj = URI.parse(URI.encode(objectKey))
      key = urlObj.host
      key << urlObj.path
      key << sort_params(urlObj.query)
      Digest::SHA256.hexdigest(key)
    end

    # @param query [String]
    # @return [String]
    def sort_params(query)
      if query.nil? or query.empty?
        return ""
      end
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
      #[0] = "". [1]= "api". [2]="wow", [3]= what we want
      URI.parse(URI.encode(objectKey)).path.split("/")[3]
    end

    # @param query [String]
    # @return [TrueClass|FalseClass]
    def has_fields?(query)
      not query.scan(/fields=/).empty?
    end

    # @param url [String]
    # @param header [Hash]
    # @return [Net::HTTPResponse]
    def request_raw(url,header)
      req = @adapter.get(url,header,true)
      req.get(url,header)
    end

    def status(options = {})
      puts "Rattlecache: STATUS:"
      puts "\tentries in cache: #{entries()}"
      puts "\trequests served: #{(hits+misses)}, hits: #{hits()} (#{(100*(hits()/(hits()+misses()))).to_i}%), misses: #{misses()} (#{(100*(misses()/(hits()+misses()))).to_i}%)"
      puts "\tposts to cache: #{posts}"
    end

    def entries()
      @backend.entries()
    end

    def hits()
      @status[:hits]
    end

    def misses()
      @status[:misses]
    end

    def posts()
      @status[:posts]
    end

  end
end
