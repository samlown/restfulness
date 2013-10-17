module Restfulness
  module Resources

    # Special events that can be used in replies. The idea here is to cover
    # the basic messages that most applications will deal with in their 
    # resources.
    module Events

      # Event definitions go here. We only support a limited subset
      # so that we don't end up with loads of methods that are not used.
      # If you'd like to see another, please send us a pull request!
      SUPPORTED_EVENTS = [
        # 300 Events
        [304, :not_modified],

        # 400 Events
        [400, :bad_request],
        [401, :unauthorized],
        [402, :payment_required],
        [403, :forbidden],
        [404, :resource_not_found],
        [405, :method_not_allowed],
        [408, :request_timeout],
        [409, :conflict],
        [410, :gone],
        [422, :unprocessable_entity]
      ]

      # Main error event handler
      def error!(code, payload = "", opts = {})
        raise HTTPException.new(code, payload, opts)
      end

      SUPPORTED_EVENTS.each do |row|
        define_method("#{row[1]}!") do |*args|
          payload = args.shift || ""
          opts    = args.shift || {}
          error!(row[0], payload, opts)
        end
      end

    end

  end
end
