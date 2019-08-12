require 'rubygems'
require 'bundler'
Bundler.setup
if ENV['RACK_ENV'] != 'production'
  require 'pry-debugger-jruby'
  require 'dotenv/load'
end

Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }


run Cuba
