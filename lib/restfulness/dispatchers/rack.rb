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


        # No need to provide an empty response
        log_response(response.code)
        [response.code, response.headers, [response.payload || ""]]

      rescue HTTPException => e
        log_response(e.code)
        [e.code, {}, [e.payload || ""]]

      #rescue Exception => e
      #  log_response(500)
      #  puts
      #  puts e.message
      #  puts e.backtrace
      #  # Something unknown went wrong
      #  [500, {}, [STATUSES[500]]]
      end

      protected

      def prepare_request(env, rack_req, request)
        request.uri       = rack_req.url
        request.action    = parse_action(rack_req.request_method)
        request.query     = rack_req.GET
        request.body      = rack_req.body
        request.remote_ip = rack_req.ip
        request.headers   = prepare_headers(env)

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
        when 'OPTIONS'
          :options
        else
          raise HTTPException.new(501)
        end
      end

      def log_response(code)
        logger.info("Completed #{code} #{STATUSES[code]}")
      end

      def prepare_headers(env)
        res = {}
        env.each do |k,v|
          next unless k =~ /^HTTP_/
          res[k.sub(/^HTTP_/, '').downcase.gsub(/-/, '_').to_sym] = v
        end
        res
      end

      def logger
        Restfulness.logger
      end

    end

  end

end
