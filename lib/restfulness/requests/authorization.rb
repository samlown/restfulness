module Restfulness
  module Requests

    module Authorization

      def authorization
        @authorization ||= begin
          payload = authorization_header_payload
          AuthorizationHeader.new(payload) unless payload.nil?
        end
      end

      private

      def authorization_header_payload
        headers[:authorization]
      end

    end

  end
end
