
require 'rubygems'
require 'bundler/setup'

require 'restfulness' # and any other gems you need

RSpec.configure do |config|
  config.color = true

  # Avoid deprication messages with this:
  I18n.config.enforce_available_locales = false
end

# Disable any logger output
Restfulness.logger.formatter = proc {|severity, datetime, progname, msg| ""}

