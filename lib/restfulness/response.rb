
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

      perform
    end

    protected

    def perform
      if request.route
        resource = build_resource(request)

        # run callbacks, if any fail, they'll raise an error
        resource.check_callbacks

        # Perform the actual work
        result = resource.send(request.action)

        @code    ||= 200
        @payload   = JSON.encode(result)
      else
        # This is not something we can deal with, pass it on
        @code = nil
      end
    end

    def build_resource(request)
      request.route.build_resource(request, self)
    end

  end

end
