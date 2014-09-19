module Restfulness
  module HttpAuthentication

    class Basic

      # The Requests::AuthorizationHeader object generated in the request
      attr_accessor :header

      def initialize(header)
        self.header = header
      end

      # Determine if the header we were provided is valid.
      def valid?
        header.schema == 'Basic' && credentials.length == 2
      end

      # Attempt to decode the credentials provided in the header.
      def credentials
        @credentials ||= begin
          txt = ::Base64.decode64(header.params || '')
          txt.split(/:/, 2)
        end
      end

      def username
        credentials[0]
      end

      def password
        credentials[1]
      end

    end

  end
end
