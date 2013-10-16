
module Restfulness

  class Response

    # Incoming data
    attr_reader :request

    # Outgoing data
    attr_reader :code, :headers, :payload


    def initialize(request)
      @request = request

      # Default headers
      @headers = {'Content-Type' => 'application/json; charset=utf-8'}
    end

    def run
      logger.info("Responding to #{request.action.to_s.upcase} #{request.uri.to_s} from #{request.remote_ip}")

      route = request.route
      if route
        logger.info("Using resource: #{route.resource_name}")
        resource = route.build_resource(request, self)

        # run callbacks, if any fail, they'll raise an error
        resource.check_callbacks

        # Perform the actual work
        result = resource.call

        @code    ||= (result ? 200 : 204)
        @payload   = MultiJson.encode(result)
      else
        logger.error("No route found")
        # This is not something we can deal with, pass it on
        @code    = 404
        @payload = ""
      end
      update_content_length
    end

    def logger
      Restfulness.logger
    end

    protected
    
    def update_content_length
      @headers['Content-Length'] = @payload.bytesize.to_s
    end

  end

end
