module Restfulness
  class VerboseFormatter
    def call(serverity, datetime, progname, msg)
      time = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')
      sym = case serverity
            when 'ERROR'
              'EE'
            when 'INFO'
              '--'
            else
              '**'
            end
      "#{sym} #{time}: #{msg}\n"
    end
  end
end
