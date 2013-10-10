
module Restfulness

  class Dispatcher

    attr_accessor :app

    def initialize(app)
      self.app = app
    end

    def run(env)
      request = Request.new(app, env)
      if request.route
        resource = build_resource(request)

        check_callbacks(resource)
      else
        # This is not a request we can handle
        nil
      end
    end


    protected

    def build_resource(request)
      request.route.build_resource(request)
    end

  end

end
