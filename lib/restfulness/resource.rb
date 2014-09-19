module Restfulness

  class Resource
    include Resources::Events
    include Resources::Authentication

    attr_reader :request, :response

    def initialize(request, response)
      @request  = request
      @response = response
    end

    # Options is the only HTTP method support by default
    def options
      response.headers['Allow'] = self.class.supported_methods.map{ |m|
        m.to_s.upcase
      }.join(', ') 
      nil
    end

    def call
      # At some point, we might add custom callbacks here. If you really need them though,
      # you can wrap around the call method easily.
      send(request.action)
    end

    # Callbacks

    def method_allowed?
      self.class.supported_methods.include?(request.action)
    end

    def exists?
      true
    end

    def authorized?
      true
    end

    def allowed?
      true
    end

    def last_modified
      nil
    end

    def etag
      nil
    end

    def check_callbacks
      # Locale Handling
      set_locale

      # Access control
      method_not_allowed! unless method_allowed?
      unauthorized!       unless authorized?
      forbidden!          unless allowed?

      # The following callbacks only make sense for certain methods
      if [:head, :get, :patch, :delete].include?(request.action)
        resource_not_found! unless exists?

        if [:get, :head].include?(request.action)
          # Resource status
          check_etag if etag
          check_if_modified if last_modified
        end
      end
    end

    protected

    def locale
      request.http_accept_language.compatible_language_from(I18n.available_locales)
    end

    def set_locale
      I18n.locale = locale
    end

    def logger
      Restfulness.logger
    end

    private

    def check_if_modified
      date = request.headers[:if_modified_since]
      if date && date == last_modified.to_s
        not_modified!
      end
      response.headers['Last-Modified'] = last_modified
    end

    def check_etag
      tag = request.headers[:if_none_match]
      if tag && tag == etag.to_s
        not_modified!
      end
      response.headers['ETag'] = etag
    end

    class << self

      def supported_methods
        @_actions ||= (instance_methods & [:get, :put, :post, :delete, :head, :patch, :options])
      end

    end

  end

end
