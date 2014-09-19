module Restfulness
  module Resources

    # Module to support authentication in Restfulness resources.
    module Authentication

      # Parse the request headers for HTTP Basic Authentication details and
      # run the provided block.
      # If the request does not include and basic headers or the details are invalid,
      # the block will not be called.
      def authenticate_with_http_basic
        header = request.authorization
        auth = HttpAuthentication::Basic.new(header) if header
        if auth && auth.valid?
          yield auth.username, auth.password
        end
      end

    end
  end
end
