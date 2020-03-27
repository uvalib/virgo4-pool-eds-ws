require 'rubygems'
require 'cuba/test'
require 'bundler'
require 'pry-debugger-jruby'
require 'dotenv/load'
Bundler.require :default, :development
ENV['V4_JWT_KEY'] = '12345'
require_relative 'config/initializer'

Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }
claims = {
    UserID:           '',
		IsUVA:            '',
		CanPurchase:      '',
		CanLEO:           '',
		CanLEOPlus:       '',
		CanPlaceReserve:  '',
		CanBrowseReserve: '',
    UseSIS:           '',
		Role:             '',
		AuthMethod:       ''
  }

jwt_token = Rack::JWT::Token.encode(claims, ENV['V4_JWT_KEY'], 'HS256')
puts jwt_token
scope do
  header "Authorization", "Bearer #{jwt_token}"

  test 'Search' do
    #post '/api/search', {query: 'date:{<1945} AND date:{>1932} AND author:{Shelly}'}
    post '/api/search', {query: 'date:{2010 TO 2020} AND title:{animals}'}
    #puts last_response.body
    assert last_response.ok?
  end

  test 'Filters' do
    post '/api/search', {query: 'date:{1932  TO 1945} AND author:{Shelly}',
      filters: [facets: [{"facet_id"=>"SourceType", "value"=>"Academic Journals"}]
    ]
    }
    #puts last_response.body
    assert last_response.ok?
  end

  test 'Invalid format' do
    post '/api/search', {query: 'badSearch:{1999-1999} AND author:{Shelly}'}
    assert last_response.status == 400
    post '/api/search', {query: 'date:{badDate} AND author:{Shelly}'}
    assert last_response.status == 400
    post '/api/search', {query: 'date:{1999-1999} BAD author:{Shelly}'}
    assert last_response.status == 400
    #puts last_response.body
  end

# # This was used to verify boolean logic with EDS queries.
# # It's pretty slow so commented out after verifying the counts.
# test 'boolean logic' do
#   search = EDS::Search.new 'query' => 'title:{replaced}'

#   dogs_query = { 'query-1' => "TI:Dogs",
#     :searchmode=>"all",
#     :resultsperpage=>1,
#     :sort=>"relavance",
#     :highlight=>"n"
#   }
#   dog_results = search.run_search dogs_query
#   dog_count = dog_results["SearchResult"]["Statistics"]["TotalHits"]

#   cats_query = { 'query-1' => "TI:Cats",
#     :searchmode=>"all",
#     :resultsperpage=>1,
#     :sort=>"relavance",
#     :highlight=>"n"
#   }
#   cat_results = search.run_search cats_query
#   cat_count = cat_results["SearchResult"]["Statistics"]["TotalHits"]

#   or_combined_query = { 'query-1' => "TI:Dogs OR Cats",
#     :searchmode=>"all",
#     :resultsperpage=>1,
#     :sort=>"relavance",
#     :highlight=>"n"
#   }
#   or_combined_results = search.run_search or_combined_query
#   or_combined_count = or_combined_results["SearchResult"]["Statistics"]["TotalHits"]

#   or_query = { 'query-1' => "OR,TI:Dogs",
#     'query-2' => "OR,TI:Cats",
#     :searchmode=>"all",
#     :resultsperpage=>1,
#     :sort=>"relavance",
#     :highlight=>"n"
#   }
#   or_results = search.run_search or_query
#   or_count = or_results["SearchResult"]["Statistics"]["TotalHits"]

#   assert or_count == or_combined_count

#   and_query = { 'query-1' => "AND,TI:Dogs",
#                 'query-2' => "AND,TI:Cats",
#     :searchmode=>"all",
#     :resultsperpage=>1,
#     :sort=>"relavance",
#     :highlight=>"n"
#   }
#   and_results = search.run_search and_query
#   and_count = and_results["SearchResult"]["Statistics"]["TotalHits"]

#   assert (dog_count + cat_count ) == (or_count + and_count)
# end

  test 'Single Item' do
    get '/api/resource/a9h_8781893'
    assert last_response.ok?
    parsed_body = JSON.parse last_response.body
    assert parsed_body.keys.include?("fields")
  end

  test 'Failing Author with -' do
    post '/api/search', {query: 'author:{Hernández-Iturriaga}'}
    parsed_body = JSON.parse last_response.body
    assert parsed_body['group_list'].count > 1
  end

  test 'Escape : , ( )' do
    post '/api/search', {query: 'title:{Actitud hacia la Ciencia: desarrollo y validación estructural del School Science Attitude Questionnaire (SSAQ).}'}
    assert last_response.ok?
    parsed_body = JSON.parse last_response.body
    assert parsed_body['group_list'].present?

    post '/api/search', {query: 'title:{Science and Religion in the Anglo-American Periodical Press, 1860-1900: A Failed Reconciliation}'}
    assert last_response.ok?
    parsed_body = JSON.parse last_response.body
    assert parsed_body['group_list'].present?
  end

  test 'Complex logic with ()' do
    post '/api/search', {query: 'keyword: {(calico OR "tortoise shell") AND (dogs OR (cats AND queen))}'}
    assert last_response.ok?
  end

  test 'Bad Auth' do
    header "Authorization", "Bearer BadJWT"
    get '/api/resource/a9h_8781893'
    assert last_response.unauthorized?

    # These paths don't need auth
    NO_AUTH_PATHS.each do |path|
      get path
      assert last_response.ok?
    end
  end
end
