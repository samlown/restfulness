module Restfulness

  # Simple, indpendent, request interface for dealing with the incoming information
  # in a request. 
  class Request

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

    def initialize
      self.action  = nil
      self.headers = {}
      self.path    = nil
      self.query   = {}
      self.body    = nil
    end

    def params
      return @params if @params

    end

  end

end
