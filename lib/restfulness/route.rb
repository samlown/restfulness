module Restfulness

  class Route

    # The path array of eliments, :id always on end!
    attr_accessor :path

    # Reference to the class that will handle requests for this route
    attr_accessor :resource_name

    def initialize(*args)
      self.resource_name = args.pop.to_s
      self.path = args.reject{|arg| arg == :id}

      if resource_name.empty? || resource.nil? # Try to load the resource
        raise ArgumentError, "Please provide a resource!"
      end
    end

    def build_path(path)
      Path.new(self, path)
    end

    def handles?(parts)
      # Make sure same length (accounting for id)
      diff = parts.length - path.length
      return false if diff != 0 && diff != 1

      # Compare the pairs
      path.each_with_index do |slug, i|
        if slug.is_a?(String) or slug.is_a?(Numeric)
          return false if parts[i] != slug.to_s
        end
      end
      true
    end

    def resource
      resource_name.constantize
    end

    def build_resource(request, response)
      resource.new(request, response)
    end

  end

end
