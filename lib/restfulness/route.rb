module Restfulness

  class Route

    # The path array of eliments, always excluding the :id field at the end.
    attr_accessor :path

    # Reference to the class that will handle requests for this route
    attr_accessor :resource

    def initialize(path, resource)

    end

    def handles?(path)
      
    end

  end

end
