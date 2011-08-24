module Rattlecache
  class Auctionscache < Cache


    # @param backend [Rattlecache::Backend]
    # @param adapter [Battlenet::Adapter::AbstractAdapter]
    def initialize(backend, adapter)
      @adapter = adapter
      @backend = backend
    end

    # @param url [String]
    # @return [String|nil]
    def get(url,header)

      cached_data = @backend.get(sanitize(url))

      # Check if any fields are requested.
      # If yes, request without fields and look into ['lastModified']
      # if we need to fetch new or answer with our cached result.",
      if cached_data[:status] == 200
        puts "Debug: Auctionscache: cache HIT for #{url}"
        unless is_lmt_and_url_request(url)
          puts "Debug: Auctionscache: has fields. Timethings: #{cached_data[:lastModified]} < #{get_lmt(url,header)} #{cached_data[:lastModified] < get_lmt(url,header)}"
          if cached_data[:lastModified] < get_lmt(url,header)
            cached_data = {:status => 404}
          end
        else
          # if a guild is requested without additional fields,
          # simply check if this file is still valid
          if generic_needs_request?(cached_data[:header],cached_data[:lastModified])
            cached_data = {:status => 404}
         end
        end
      else
        puts "Debug: Auctionscache: cache MISS for #{url}"
      end
      cached_data
    end

    # check if the supplied url is not pointing to a .json auctions file,
    # but to a generic url for lmt and the .json url
    def is_lmt_and_url_request(url)
      not url.include?(".json")
    end

    # method to get the lastModified info for a specified url
    # @param url [String] the url for which the LMT is wanted
    # @param header [Hash] the Hash of headers for a api request
    def get_lmt(url,header)
      cached_data = @backend.get(sanitize(generic_auctions_url(url)))
      puts "Debug: get_lmt() cache result for generic url: #{cached_data[:status]}"
      # if the object was not in the cache or it is expired
      if cached_data[:status] != 200 or generic_needs_request?(cached_data[:header],cached_data[:lastModified])
        # request it from the api
        request_generic(url,header)
        # and load the new object
        cached_data = @backend.get(sanitize(generic_auctions_url(url)))
      end
      # this a JS milliseconds timestamp, we only do seconds!
      Time.at(JSON.parse(cached_data[:object])["files"][0]["lastModified"]/1000)
    end

    def request_generic(url,header)
      # need to request the generic guild response
      url = generic_auctions_url(url)
      # request it from the API:
      got = request_raw(url,header)
      @backend.post({:key => sanitize(url),:header => got.header.to_hash, :data => got.body}) # and put into cache
    end


    def generic_auctions_url(url)
      u = URI.parse(url)
      u.path=("/api/wow/"+u.path.gsub("-data","/data").gsub(/\/auctions.*\.json$/,""))
      u.to_s
    end
  end
end