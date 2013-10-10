module Restfulness

  module Dispatchers

    class Rack < Dispatcher

      def call(env)
        rack_req = ::Rack::Request.new(env)

        # Make sure we understand the request
        request = Request.new(app)
        prepare_request(rack_req, request)

        # Prepare a suitable response
        response = Response.new(request)

        # No need to provide an empty response
        if response.code
          [response.code, response.headers, response.payload]
        else
          nil
        end
      rescue HTTPException => e
        [e.code, {}, e.payload]
      rescue
        # Something unkown went wrong
        [504, {}, "Internal server error"]
      end

      protected

      def prepare_request(rack_req, request)
        request.uri     = rack_req.url
        request.action  = parse_action(rack_req.request_method)
        request.headers = prepare_headers(rack_req.headers)
        request.query   = rack_req.GET
        request.body    = rack_req.body
      end

      def parse_action(action)
        case action
        when 'DELETE'
          :delete
        when 'GET'
          :get
        when 'HEAD'
          :head
        when 'POST'
          :post
        when 'PUT'
          :put
        else
          raise "Invalid action!"
        end
      end

      def prepare_headers(headers)
        res = {}
        headers.each do |k,v|
          res[k.downcase.gsub(/-/, '_').to_sym] = v
        end
        res
      end

    end

  end

end
