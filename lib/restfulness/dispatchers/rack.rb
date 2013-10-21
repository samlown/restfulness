module Restfulness

  module Dispatchers

    class Rack < Dispatcher

      def call(env)
        rack_req = ::Rack::Request.new(env)

        # Make sure we understand the request
        request = Request.new(app)
        prepare_request(env, rack_req, request)

        # Prepare a suitable response
        response = Response.new(request)
        response.run

        [response.status, response.headers, [response.payload || ""]]
      end

      protected

      def prepare_request(env, rack_req, request)
        request.uri        = rack_req.url
        request.action     = parse_action(rack_req.request_method)
        request.query      = rack_req.GET
        request.body       = rack_req.body
        request.headers    = prepare_headers(env)

        request.remote_ip  = rack_req.ip
        request.user_agent = rack_req.user_agent

        # Sometimes rack removes content type from headers
        request.headers[:content_type] ||= rack_req.content_type
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
        when 'PATCH'
          :patch
        when 'OPTIONS'
          :options
        else
          raise HTTPException.new(501)
        end
      end

      def prepare_headers(env)
        res = {}
        env.each do |k,v|
          next unless k =~ /^HTTP_/
          res[k.sub(/^HTTP_/, '').downcase.gsub(/-/, '_').to_sym] = v
        end
        res
      end

    end

  end

end
