
module Restfulness

  class Dispatcher

    attr_accessor :app

    def initialize(app)
      self.app = app
    end

  end

end
