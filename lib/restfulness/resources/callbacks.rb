
require 'active_support/concern'

module Restfulness
  module Resources

    # The default set of callbacks that may be overwritten by the developer.
    module Callbacks
      extend ActiveSupport::Concern

      def exists?
        true
      end

      def forbidden?
        false
      end

      def authorized?
        true
      end

      def last_updated
        nil
      end

    end

  end
end
