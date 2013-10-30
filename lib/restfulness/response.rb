
module Restfulness

  class Response

    # Incoming data
    attr_reader :request

    # Outgoing data
    attr_reader :status, :headers, :payload


    def initialize(request)
      @request = request
      @headers = {}
    end

    def run
      route = request.route
      if route
        resource = route.build_resource(request, self)

        # run callbacks, if any fail, they'll raise an error
        resource.check_callbacks

        # Perform the actual work
        result = resource.call

        update_status_and_payload(result.nil? ? 204 : 200, result)
      else
        update_status_and_payload(404)
      end

    rescue HTTPException => e # Deal with HTTP exceptions
      headers.update(e.headers)
      update_status_and_payload(e.status, e.payload)
    end

    def content_length
      payload.to_s.bytesize.to_s
    end

    protected

    def update_status_and_payload(status, payload = "")
      self.status  = status
      self.payload = payload
    end

    def status=(code)
      @status = code
    end

    def payload=(body)
      if body.nil? || body.is_a?(String)
        @payload = body.to_s
        update_content_headers(:text)
      else
        @payload = MultiJson.encode(body)
        update_content_headers(:json)
      end
    end
    
    def update_content_headers(type = :json)
      case type
      when :json
        headers['Content-Type'] = 'application/json; charset=utf-8'
      else # Assume text
        headers['Content-Type'] = 'text/plain; charset=utf-8'
      end
      headers['Content-Length'] = content_length
    end

  end
end
