module Restfulness
  module Requests

    # Handle the HTTP Authorization header payload to automatically extract the scheme
    # and parameters.
    class AuthorizationHeader

      attr_accessor :schema, :params

      def initialize(payload)
        (self.schema, self.params) = payload.strip.split(' ', 2)
      end

      def schema=(txt)
        # Make sure we're in Titlecase
        @schema = txt.slice(0,1).capitalize + txt.slice(1..-1).downcase
      end

    end

  end
end
