module Restfulness

  class Route

    # The path array of eliments, :id always on end!
    attr_accessor :path

    # Reference to the class that will handle requests for this route
    attr_accessor :resource

    def initialize(*args)
      self.path = []
      args.each do |arg|
        case arg
        when Numeric, String, Symbol
          path << arg if arg != :id
        when Class
          self.resource = arg
        end
      end

      if resource.nil? || !(resource < Resource)
        raise "Route error: \"#{path.join('/')}\" is missing resource!" 
      end
    end

    def build_path(path)
      Path.new(self, path)
    end

    def handles?(parts)
      path.each_with_index do |slug, i|
        if slug.is_a?(String) or slug.is_a?(Numeric)
          return false if parts[i] != slug.to_s
        end
      end
      true
    end

    def build_resource(request)
      resource.new(request)
    end

  end

end
