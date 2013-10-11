
module Restfulness

  class HTTPException < ::StandardError

    attr_accessor :code, :payload, :headers

    def initialize(code, payload = nil, opts = {})
      @code    = code
      @payload = payload
      @headers = opts[:headers]
      super(opts[:message] || STATUSES[code])
    end

  end

end
