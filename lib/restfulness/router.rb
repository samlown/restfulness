
module Restfulness

  class Router

    attr_accessor :routes, :current_scope

    def initialize(&block)
      self.routes = []
      self.current_scope = []
      instance_eval(&block) if block_given?
    end

    def add(*args, &block)
      # Do we need to pretend we've been given a scope?
      scope(*args[0..-2], &block) if block_given?
      routes << Route.new(*(current_scope + args))
    end

    def scope(*args, &block)
      old_scope = current_scope
      self.current_scope += args
      instance_eval(&block) if block_given?
      self.current_scope = old_scope
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
