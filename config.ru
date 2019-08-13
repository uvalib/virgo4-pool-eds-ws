require 'rubygems'
require 'bundler'
require 'logger'
Bundler.setup

$logger = Logger.new($stdout)
$logger.level = Logger::INFO

if ENV['RACK_ENV'] != 'production'
  require 'pry-debugger-jruby'
  require 'dotenv/load'
  $logger.level = Logger::DEBUG
end

Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }

run Cuba
