require 'rubygems'
require 'cuba/test'
require 'bundler'
require 'pry-debugger-jruby'
require 'dotenv/load'
Bundler.require :default, :development

$logger = Logger.new($stdout)
$logger.level = Logger::DEBUG

Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }

scope do
  test 'Search' do
    #post '/api/search', {query: 'date:{<1945} AND date:{>1932} AND author:{Shelly}'}
    post '/api/search', {query: 'date:{1932  TO 1945} AND author:{Shelly}'}
    #puts last_response.body
    assert last_response.ok?
  end

  test 'Filters' do
    post '/api/search', {query: 'date:{1932  TO 1945} AND author:{Shelly}',
      filters: [{"name"=>"SourceType", "value"=>"Academic Journals"},
                {"name"=>"ContentProvider", "value"=>"Academic Search Complete"}

    ]
    }
    #puts last_response.body
    assert last_response.ok?
  end

  test 'GET method' do
    get '/api/search', {query: 'date:{1932  TO 1945} AND author:{Shelly}'}
    assert last_response.ok?
  end

  test 'Invalid format' do
    get '/api/search', {query: 'baddate:{1932  TO 1945} AND author:{Shelly}'}

  end
end
