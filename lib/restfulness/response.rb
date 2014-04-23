
module Restfulness

  class Response

    # Incoming data
    attr_reader :request

    # The generated resource object
    attr_reader :resource

    # Outgoing data
    attr_reader :status, :headers, :payload


    def initialize(request)
      @request = request
      @headers = {}
    end

    def run
      @log_begin_at = Time.now
      route = request.route
      if route
        self.resource = route.build_resource(request, self)

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

    rescue StandardError, LoadError, SyntaxError => e
      # Useful coding error handling, with backtrace
      log_exception(e)
      update_status_and_payload(500, e.message + "\n")

    ensure
      log! if status
    end

    def content_length
      payload.to_s.bytesize.to_s
    end

    protected

    def resource=(obj)
      @resource = obj
    end

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
        update_content_headers(:text) unless @payload.empty?
      else
        @payload = MultiJson.encode(body)
        update_content_headers(:json) unless @payload.empty?
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

    def log!
      dur = @log_begin_at ? Time.now - @log_begin_at : 0.0
      uri = request.uri

      resource_name = resource ? resource.class.to_s : 'Error'
      # We're only interested in parsed parameters.
      params = request.sanitized_params

      msg = %{%s "%s %s%s" %s %d %s %s %0.4fs %s} % [
        request.remote_ip,
        request.action.to_s.upcase,
        uri.path,
        uri.query ? "?#{request.sanitized_query_string}" : '',
        resource_name,
        status.to_s[0..3],
        STATUSES[status],
        content_length,
        dur,
        params ? params.inspect : ''
      ]
      Restfulness.logger.info(msg)
    end

    def log_exception(e)
      string = "#{e.class}: #{e.message}\n"
      string << e.backtrace.map { |l| "\t#{l}" }.join("\n")
      Restfulness.logger.error(string)
    end

  end
end
