require "active_support/rescuable"

module Restfulness

  class Response
    include ActiveSupport::Rescuable

    # rescue are retrieved on reverse order

    rescue_from StandardError, LoadError, SyntaxError  do |exception|
      log_exception(exception)
      update_status_and_payload(500, exception.message + "\n")
    end

    rescue_from HTTPException do |exception|
      headers.update(exception.headers)
      update_status_and_payload(exception.status, exception.payload)
    end

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
    rescue Exception => e
      rescue_with_handler(e)
    ensure
      log! if status
    end

    def content_length
      payload.to_s.bytesize.to_s
    end

    # Override the status of this response.
    def status=(code)
      @status = code.to_i
    end

    protected

    def resource=(obj)
      @resource = obj
    end

    def update_status_and_payload(status, payload = "")
      self.status  = status unless self.status.present?
      self.payload = payload
    end

    def payload=(body)
      type = content_type_from_accept_header
      if body.nil?
        @payload = ""
      elsif body.is_a?(String)
        # Implies that the body was already prepared, and we should rely on accept headers or assume text
        @payload = body
        update_content_headers(type || :text) unless @payload.empty?
      elsif type && type == :xml
        # Try to use a #to_xml if available, or just use to_s.
        @payload = (body.respond_to?(:to_xml) ? body.to_xml : body).to_s
        update_content_headers(:xml) unless @payload.empty?
      else
        # DEFAULT: Assume we want JSON
        @payload = MultiJson.encode(body)
        update_content_headers(:json) unless @payload.empty?
      end
    end

    def content_type_from_accept_header
      accept = self.request.accept
      if accept
        if accept.json?
          :json
        elsif accept.xml?
          :xml
        elsif accept.text?
          :text
        end
      else
        nil
      end
    end

    def update_content_headers(type = :json)
      if headers['Content-Type'].to_s.empty?
        case type
        when :json
          headers['Content-Type'] = 'application/json; charset=utf-8'
        when :xml
          headers['Content-Type'] = 'application/xml; charset=utf-8'
        else # Assume text
          headers['Content-Type'] = 'text/plain; charset=utf-8'
        end
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

    def rescue_with_handler(exception)
      if (exception.respond_to?(:original_exception) &&
        (orig_exception = exception.original_exception) &&
        handler_for_rescue(orig_exception))
        exception = orig_exception
      end
      super(exception)
    end

  end
end
