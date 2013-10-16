
module Restfulness

  class HTTPException < ::StandardError

    attr_accessor :status, :payload, :headers

    def initialize(status, payload = "", opts = {})
      @status  = status
      @payload = payload
      @headers = opts[:headers] || {}
      super(opts[:message] || STATUSES[status])
    end

  end

end
