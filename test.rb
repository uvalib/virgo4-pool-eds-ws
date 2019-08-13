require 'rubygems'
require 'cuba/test'
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

scope do
  test 'Search' do
    post '/api/search', {query: 'title:{bananas}'}
    assert last_response.ok?
  end
end
