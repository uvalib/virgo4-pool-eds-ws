require 'rubygems'
require 'cuba/test'
require 'bundler'
Bundler.setup
if ENV['RACK_ENV'] != 'production'
  require 'pry-debugger-jruby'
  require 'dotenv/load'
end
Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }

scope do
  test 'Search' do
    get '/api/search', {query: 'title:{bananas}'}
    assert last_response.ok?
  end
end
