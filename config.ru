require 'rubygems'
require 'bundler'
Bundler.setup
Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }

#if ENV['RACK_ENV'] != 'production'
#  require 'byebug'
#  require 'dotenv/load'
#end

run Cuba
