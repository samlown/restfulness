module Restfulness

  # 
  # The Restulness::Application is the starting point. It'll deal with 
  # defining the initial configuration, and handle incoming requests
  # from rack. 
  #
  # Build your own Restfulness applications by inheriting from this class:
  #
  #   class MyApp < Restfulness::Application
  #
  #     routes do
  #       scope 'api' do
  #         add 'journey', JourneyResource
  #         add 'journeys', JourneyCollectionResource
  #       end
  #     end
  #
  #   end
  #
  class Application

    def router
      self.class.router
    end

    # Rack Handling.
    # Forward rack call to dispatcher
    def call(env)
      @app ||= build_rack_app
      @app.call(env)
    end

    protected

    def build_rack_app
      this = self
      dispatcher = Dispatchers::Rack.new(self)
      Rack::Builder.new do
        this.class.middlewares.each do |middleware|
          use middleware
        end
        run dispatcher
      end
    end

    class << self

      attr_accessor :router, :middlewares

      def routes(&block)
        # Store the block so we can parse it at run time (autoload win!)
        @router = Router.new(&block)
      end

      # A simple array of rack middlewares that will be applied
      # before handling the request in Restfulness.
      #
      # Probably most useful for adding the ActiveDispatch::Reloader
      # as used by Rails to reload on each request. e.g.
      #
      #    middlewares << ActiveDispatch::Reloader
      #
      def middlewares
        @middlewares ||= [
          Rack::CommonLogger,
          Rack::ShowExceptions
        ]
      end

      # Quick access to the Restfulness logger.
      def logger
        Restfulness.logger
      end

      # Override the default Restfulness logger.
      def logger=(logger)
        Restfulness.logger = logger
      end

    end

  end
end
