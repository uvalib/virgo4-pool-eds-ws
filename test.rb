require 'rubygems'
require 'cuba/test'
require 'bundler'
require 'logger'
require 'pry-debugger-jruby'
require 'dotenv/load'
Bundler.setup

$logger = Logger.new($stdout)
$logger.level = Logger::DEBUG

Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }

scope do
  test 'Search' do
    post '/api/search', {query: 'title:{google}'}
    puts last_response.body
    assert last_response.ok?
  end
end
