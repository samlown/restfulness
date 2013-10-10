
module Restfulness

  class Router

    attr_accessor :routes

    def initialize(opts = {}, &block)
      self.routes = []
      instance_eval(&block)
    end

    def add(*args)
      routes << Route.new(*args)
    end

    def route_for(path)
      parts = path.split(/\//)
      routes.each do |route|
        return route if route.handles?(parts)
      end
      nil
    end

    protected

    def parse_path(url)
      parser = URI::Parser.new
      parser.parse(url)

    end

  end

end
