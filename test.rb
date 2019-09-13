require 'rubygems'
require 'cuba/test'
require 'bundler'
require 'pry-debugger-jruby'
require 'dotenv/load'
Bundler.require :default, :development

require_relative 'config/initializer'

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
      filters: [{"facet_id"=>"SourceType", "value"=>"Academic Journals"}
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

  # This was used to verify boolean logic with EDS queries.
  # It's pretty slow so commented out after verifying the counts.
  test 'boolean logic' do
    search = EDS::Search.new 'query' => 'title:{replaced}'

    dogs_query = { 'query-1' => "TI:Dogs",
      :searchmode=>"all",
      :resultsperpage=>1,
      :sort=>"relavance",
      :highlight=>"n"
    }
    dog_results = search.run_search dogs_query
    dog_count = dog_results["SearchResult"]["Statistics"]["TotalHits"]

    cats_query = { 'query-1' => "TI:Cats",
      :searchmode=>"all",
      :resultsperpage=>1,
      :sort=>"relavance",
      :highlight=>"n"
    }
    cat_results = search.run_search cats_query
    cat_count = cat_results["SearchResult"]["Statistics"]["TotalHits"]

    or_combined_query = { 'query-1' => "TI:Dogs OR Cats",
      :searchmode=>"all",
      :resultsperpage=>1,
      :sort=>"relavance",
      :highlight=>"n"
    }
    or_combined_results = search.run_search or_combined_query
    or_combined_count = or_combined_results["SearchResult"]["Statistics"]["TotalHits"]

    or_query = { 'query-1' => "OR,TI:Dogs",
      'query-2' => "OR,TI:Cats",
      :searchmode=>"all",
      :resultsperpage=>1,
      :sort=>"relavance",
      :highlight=>"n"
    }
    or_results = search.run_search or_query
    or_count = or_results["SearchResult"]["Statistics"]["TotalHits"]

    assert or_count == or_combined_count

    and_query = { 'query-1' => "AND,TI:Dogs",
                  'query-2' => "AND,TI:Cats",
      :searchmode=>"all",
      :resultsperpage=>1,
      :sort=>"relavance",
      :highlight=>"n"
    }
    and_results = search.run_search and_query
    and_count = and_results["SearchResult"]["Statistics"]["TotalHits"]

    assert (dog_count + cat_count ) == (or_count + and_count)


  end
end
