module Restfulness

  # Simple, indpendent, request interface for dealing with the incoming information
  # in a request. 
  #
  # Currently wraps around the information provided in a Rack Request object.
  class Request

    # Who does this request belong to?
    attr_reader :app

    # System environmen
    attr_reader :env

    # The HTTP action being handled
    attr_accessor :action

    # Hash of HTTP headers. Keys always normalized to lower-case symbols with underscore.
    attr_accessor :headers

    # The route that has been applied to this request
    attr_accessor :route

    # Path object of the current URL being accessed
    attr_accessor :path

    # Query parameters included in the URL
    attr_accessor :query

    # Raw HTTP body, for POST and PUT requests.
    attr_accessor :body

    # Parsed parameters from the body
    attr_reader :params

    # The resource that will be performing the action
    attr_reader :resource


    def initialize(app, env)
      self.app = app
      self.env = env

      # Prepare basics
      self.action  = nil
      self.headers = {}
      self.path    = nil
      self.query   = {}
      self.body    = nil

      parse_environment
    end

    def params
      return @params if @params
    end

    protected

    def parse_environment
      rack_req = ::Rack::Request.new(env)
      rack_req
    end

    def parse_action(action)
      
    end

  end
end
