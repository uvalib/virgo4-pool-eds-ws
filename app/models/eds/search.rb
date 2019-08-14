class EDS::Search < EDS
  require 'virgo_parser'
  require 'active_support/core_ext/hash'

  attr_accessor :response, :params

  def initialize params
    self.params = params
    if params['pagination'].nil?
      # default pagination
      self.params['pagination'] = {'start' => 0, 'rows' => 20}
    end
    self.response = {}
    search
  end

  def search
    ensure_login do

      search_response = self.class.get('/edsapi/rest/Search', query: search_params,
                                       headers: auth_headers)
      check_session search_response

      stats = search_response['SearchResult']['Statistics']
      total_hits = stats['TotalHits']
      search_time = stats['TotalSearchTime']

      available_facets = search_response['SearchResult']['AvailableFacets']

      records = search_response['SearchResult']['Data']['Records']

      self.response = {
        record_list: records,
        pagination: params['pagination'].merge(total: total_hits),
        elapsed_ms: search_time,
        available_facets: available_facets,
        confidence: 'low'
      }.symbolize_keys

    end
  end

  private
  def search_params
    eds_query = VirgoParser::EDS.parse params['query']
    { query: eds_query,
      searchmode: 'all',
      resultsperpage: params['pagination']['rows'],
      sort: 'relavance',
      highlight: 'n',
      includeimagequickview: 'y'
    }
  end

end
