
module Restfulness

  # The Path object is provided in request objects to provide easy access
  # to parameters included in the URI's path.
  class Path

    attr_accessor :route, :components, :params

    def initialize(route, string)
      self.route = route
      parse(string)
    end

    def to_s
      '/' + components.join('/')
    end

    def [](index)
      if key.is_a?(Integer)
        components[index]
      else
        params[index]
      end
    end

    protected

    def parse(string)
      self.components = string.split(/\//)

      # Make sure we have the id available when parsing
      path = route.path + [:id]

      # Parametize values that need it
      path.each_with_index do |value, i|
        if value.is_a?(Symbol)
          params[value] = components[i]
        end
      end
    end

  end

end
