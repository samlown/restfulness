module Restfulness

  class Resource

    attr_reader :request, :response

    def initialize(request, response)
      @request  = request
      @response = response
    end

    # Callbacks

    def method_allowed?
      self.class.supported_actions.include?(request.action)
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
      raise HTTPException.new(401) unless resource.authorized?
      raise HTTPException.new(403) unless resource.allowed?
      raise HTTPException.new(404) unless resource.exists?

      # Resource status
      check_etag        if etag
      check_if_modified if last_modified
    end

    ##


    protected

    def error(code, payload = nil, opts = {})
      raise HTTPException.new(code, payload, opts)
    end


    private

    def check_if_modified
      date = request.headers[:if_modified_since]
      if date && date == last_modified.to_s
        raise HTTPException.new(304)
      end
    end

    def check_etag
      tag = request.headers[:if_none_match]
      if tag && tag == etag.to_s
        raise HTTPException.new(304)
      end
    end

    class << self

      def supported_actions
        @_actions ||= (instance_methods & [:get, :put, :post, :delete, :head])
      end

    end

  end

end
