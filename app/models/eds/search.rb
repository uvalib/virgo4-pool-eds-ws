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
    self.errors = []
    search
  end

  def search
    ensure_login do
      $logger.debug "Request Params: #{params}"
      $logger.debug "EDS Params: #{search_params}"

      search_response = self.class.get('/edsapi/rest/Search',
                                       query: search_params,
                                       headers: auth_headers)
      check_session search_response

      stats = search_response['SearchResult']['Statistics']
      total_hits = stats['TotalHits']
      search_time = stats['TotalSearchTime']

      facet_list = search_response['SearchResult']['AvailableFacets'] || []
      available_facets = facet_list.map {|facet| facet['Id']}

      records = search_response['SearchResult']['Data']['Records'] || []

      confidence = 'medium'
      if total_hits == 1
        confidence = 'exact'
      end

      self.response = {
        record_list: records,
        pagination: params['pagination'].merge(total: total_hits),
        available_facets: available_facets,
        facet_list: facet_list,
        confidence: confidence,
        debug: {eds_time: search_time}
      }.deep_symbolize_keys

    end
  end

  private
  def search_params
    eds_query = VirgoParser::EDS.parse params['query']
    facet_filter = get_facets
    { query: eds_query,
      facetfilter: facet_filter,
      # includefacets might need to be optional
      includefacets: 'y',
      searchmode: 'all',
      resultsperpage: params['pagination']['rows'],
      sort: 'relavance',
      view: 'detailed',
      highlight: 'n',
      includeimagequickview: 'y'
    }.delete_if {|k, v| v.blank? }
  end

  def get_facets
    if params['filters'].blank?
      return nil
    end
    facet_str = "1"
    params['filters'].each do |filter|
      facet_str += ",#{filter['name']}:#{filter['value']}"
    end
    facet_str
  end

end
