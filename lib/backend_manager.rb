module Rattlecache
  module Backend

    class InvalidBackend < Exception; end

    extend self

    attr_reader :backends
    
    @backends = {
      :filesystem => "Filesystem"
      #:redis => "Redis",
      #:somOtherCoolBackend => "someOther"
    }

    def fetch(backend_name)
      unless @backends.include?(backend_name)
        raise InvalidBackend.new("#{backend_name.to_s} is not a valid backend!")
      end

      backend_class = adapters[adapter_name]
      return load_backend(backend_name, backend_class)
    end

    def register(identifier, klass)
      @backends[identifier] = klass
    end

    private

      def load_backend(backend_name, klass_name)
        begin
          klass = Rattlecache::Backend.const_get("#{klass_name}", false)
        rescue NameError
          begin
            backend_file = "rattlecache/backends/#{backend_name.to_s}"
            require backend_file
            klass = Rattlecache::Backend.const_get("#{klass_name}", false)
          rescue LoadError
            raise InvalidAdapter.new("backend #{klass_name} does not exist, and file #{backend_file} does not exist")
          rescue NameError
            raise InvalidAdapter.new("expected #{backend_file} to define Rattlecache::Backend::#{klass_name}")
          end
        end

        return klass.new
      end
  end
end