
module Restfulness

  class Response

    attr_accessor :app

    attr_accessor :code

    attr_accessor :headers

    attr_accessor :payload

    def initialize(app, request)

    end

  end

end
