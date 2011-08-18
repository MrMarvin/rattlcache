require 'backend_manager'

module Rattlecache

  class Cache
    
    def initialize(backend = :filesystem)
      @backend = Rattlecache::Backend.fetch(backend)
    end
    
    def get(url)
      @backend.get()
    end
    
    def post(object)
      @backend.post(object)
    end
    
  end
  
end
