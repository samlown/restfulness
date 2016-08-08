module Restfulness
  module Resources

    # Special events that can be used in replies. The idea here is to cover
    # the basic messages that most applications will deal with in their 
    # resources.
    module Events

      SUCCESS_EVENTS = [
        [200, :ok],
        [201, :created],
        [202, :accepted],
        [203, :non_authoritative],
        [203, :non_authoritative_information],
        [204, :no_content],
        [205, :reset_content]
      ]

      # Event definitions go here. We only support a limited subset
      # so that we don't end up with loads of methods that are not used.
      # If you'd like to see another, please send us a pull request!
      EXCEPTION_EVENTS = [
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

      EXCEPTION_EVENTS.each do |row|
        define_method("#{row[1]}!") do |*args|
          payload = args.shift || ""
          opts    = args.shift || {}
          error!(row[0], payload, opts)
        end
      end

      SUCCESS_EVENTS.each do |row|
        define_method("#{row[1]}") do |*args|
          response.status = row[0]
          return args.first
        end
      end

    end

  end
end
