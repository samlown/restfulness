
module Restfulness

  class Path

    # List of components of the path
    attr_accessor :components

    # Are there any parameters in the path?
    attr_accessor :params

    def initialize(string)
      parse(string)
    end

    def to_s
      '/' + components.join('/')
    end

    def [](index)
      if key.is_a?(Integer)
        components[index]
      else
        attributes[index]
      end
    end

    protected

    def parse(string)
      self.components = string.split(/\//)
      components.each do |c|
        if c.is_a?(Symbol)

        end
      end
    end

  end

end
