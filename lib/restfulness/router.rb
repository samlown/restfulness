
module Restfulness

  class Router

    attr_accessor :routes

    def initialize(opts = {}, &block)
      self.routes = []
      instance_eval(&block)
    end

    def add(*args)
      path     = []
      resource = nil
      args.each do |arg|
        case arg
        when String, Symbole
          path << arg
        when Class
          resource = arg
        end
      end

      if resource.nil?
        raise "Route \"#{path.join('/')}\" is missing resource!" 
      end

      routes << Route.new(path, resource)
    end

    def match(request)
      
    end

    protected

    def parse_path(url)
      parser = URI::Parser.new
      parser.parse(url)

    end

  end

end
