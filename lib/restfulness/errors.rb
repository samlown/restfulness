
module Restfulness

  class Error < ::StandardError

    # Error code to send via HTTP
    attr_accessor :code

    # Content to send to the user despite the fact an error has ocurred
    attr_accessor :payload

    # Message to include in the logs
    attr_accessor :message
  end

end
