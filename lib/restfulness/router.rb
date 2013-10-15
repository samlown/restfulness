
module Restfulness

  class Router

    attr_accessor :routes

    def initialize(&block)
      self.routes = []
      instance_eval(&block) if block_given?
    end

    def add(*args)
      routes << Route.new(*args)
    end

    def route_for(path)
      parts = path.gsub(/^\/|\/$/, '').split(/\//)
      routes.each do |route|
        return route if route.handles?(parts)
      end
      nil
    end

  end

end
