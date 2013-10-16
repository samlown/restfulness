
require 'rubygems'
require 'bundler/setup'

require 'restfulness' # and any other gems you need

RSpec.configure do |config|
  config.color_enabled = true
end

# Disable any logger output
Restfulness.logger.formatter = proc {|severity, datetime, progname, msg| ""}

