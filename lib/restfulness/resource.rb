module Restfulness

  class Resource

    attr_reader :request, :response

    def initialize(request, response)
      @request  = request
      @response = response
    end

    # Options is the only HTTP method support by default
    def options
      response.headers['Allow'] = self.class.supported_methods.map{ |m|
        m.to_s.upcase
      }.join(', ') 
      nil
    end

    def call
      send(request.action)
    end

    # Callbacks

    def method_allowed?
      self.class.supported_methods.include?(request.action)
    end

    def exists?
      true
    end

    def authorized?
      true
    end

    def allowed?
      true
    end

    def last_modified
      nil
    end

    def etag
      nil
    end

    def check_callbacks
      # Access control
      raise HTTPException.new(405) unless method_allowed?
      raise HTTPException.new(401) unless authorized?
      raise HTTPException.new(403) unless allowed?
      raise HTTPException.new(404) unless exists?

      # Resource status
      check_etag if etag
      check_if_modified if last_modified
    end

    ##


    protected

    def error(code, payload = nil, opts = {})
      raise HTTPException.new(code, payload, opts)
    end

    def logger
      Restfulness.logger
    end


    private

    def check_if_modified
      date = request.headers[:if_modified_since]
      if date && date == last_modified.to_s
        raise HTTPException.new(304)
      end
      response.headers['Last-Modified'] = last_modified
    end

    def check_etag
      tag = request.headers[:if_none_match]
      if tag && tag == etag.to_s
        raise HTTPException.new(304)
      end
      response.headers['ETag'] = etag
    end

    class << self

      def supported_methods
        @_actions ||= (instance_methods & [:get, :put, :post, :delete, :head, :patch, :options])
      end

    end

  end

end
