
module Restfulness

  class BasicFormatter

    def call(severity, time, progname, msg)
      # We don't care about the bumf, just show the msg
      "#{msg}\n"
    end

  end

end
