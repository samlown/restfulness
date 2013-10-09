module Restfulness

  class Resource
    include Resources::Callbacks

    attr_reader :request

    def initialize(request)
      self.request = request
    end

    def 

    protected

    def error(code, payload = nil, msg = nil)
      raise Error.new(code, payload, msg)
    end

    class << self

      def supported_actions
        @_actions ||= (instance_methods & [:get, :put, :post, :delete, :head])
      end

    end

  end

end
