module Restfulness

  module Rack

    class Logger < ::Rack::CommonLogger

      def call(env)
        # This is a bit lame, but it is easier than re-writing 
        # the log method in Rack CommonLogger.
        # Not sure why the rack developers thought it would be
        # a good idea to use a local variable for this!
        @logger = Restfulness.logger
        super(env)
      end

    end

  end

end
