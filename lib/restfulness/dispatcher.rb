
module Restfulness

  class Dispatcher

    def run(request)
      if request.route
        resource = build_resource(request)

        check_callbacks(resource)
        
      else
        # This is not a request we can handle
        nil
      end
    rescue Error => e


    end


    protected

    def build_resource(request)
      request.route.build_resource(request)
    end

  end

end
