module Restfulness

  # Simple, indpendent, request interface for dealing with the incoming information
  # in a request. 
  #
  # Currently wraps around the information provided in a Rack Request object.
  class Request
    include Requests::Authorization

    # Who does this request belong to?
    attr_reader :app

    # The HTTP action being handled
    attr_accessor :action

    # Hash of HTTP headers. Keys always normalized to lower-case symbols with underscore.
    attr_accessor :headers

    # Ruby URI object
    attr_reader :uri

    # Raw HTTP body, for POST and PUT requests.
    attr_accessor :body

    # Additional useful fields
    attr_accessor :remote_ip, :user_agent

    def initialize(app)
      @app = app

      # Prepare basics
      self.action  = nil
      self.headers = {}
      self.body    = nil
    end

    def uri=(uri)
      @uri = URI(uri)
    end

    def path
      @path ||= (route ? route.build_path(uri.path) : nil)
    end

    def route
      # Determine the route from the uri
      @route ||= app.router.route_for(uri.path)
    end

    def query
      @query ||= ::Rack::Utils.parse_nested_query(uri.query).with_indifferent_access
    end

    def sanitized_query_string
      @sanitized_query ||= uri.query ? Sanitizer.sanitize_query_string(uri.query) : ''
    end

    def params
      return @params if @params || body.nil?
      case headers[:content_type]
        when /application\/json/
          begin
            @params = MultiJson.decode(body)
          rescue MultiJson::LoadError
            raise HTTPException.new(400)
          end
      else
        raise HTTPException.new(406)
      end
    end

    def sanitized_params
      # Note: this returns nil if #params has not been called
      @sanitized_params ||= @params ? Sanitizer.sanitize_hash(@params) : nil
    end

    # Provide a wrapper for the http_accept_language parser
    def http_accept_language
      @http_accept_language = HttpAcceptLanguage::Parser.new(headers[:accept_language])
    end

    [:get, :post, :put, :patch, :delete, :head, :options].each do |m|
      define_method("#{m}?") do
        action == m
      end
    end

  end
end
