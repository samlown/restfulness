
module Restfulness

  class Response

    # Incoming data
    attr_reader :request

    # Outgoing data
    attr_reader :code, :headers, :payload


    def initialize(request)
      @request = request

      # Default headers
      @headers = {'Content-Type' => 'application/json'}
    end

    def run
      route = request.route
      if route
        resource = route.build_resource(request, self)

        # run callbacks, if any fail, they'll raise an error
        resource.check_callbacks

        # Perform the actual work
        result = resource.call

        @code    ||= 200
        @payload   = MultiJson.encode(result)
      else
        # This is not something we can deal with, pass it on
        @code    = nil
        @payload = nil
      end
    end

  end

end
