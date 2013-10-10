
module Restfulness

  class HTTPException < ::StandardError

    attr_accessor :code, :payload, :message, :headers

    def initialize(code, payload, opts = {})
      @code    = code
      @payload = payload
      @headers = opts[:headers]
      @message = opts[:message] || STATUSES[code]
    end

  end

end
