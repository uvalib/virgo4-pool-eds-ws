class EDS::Search < EDS
  require 'virgo_parser'
  require 'active_support/core_ext/hash'

  attr_accessor :response, :params, :parsed_query

  # Default Facets are suggested to be applied by default.
  # This is formatted to match facets returned by EDS.
  # The API response format is in app/views/_default_facets.jbuilder
  DEFAULT_FACETS= [{'Id' => 'PeerReviewedFacet', 'Label' => 'Peer Reviewed Only',
                    'AvailableFacetValues' =>[ {'Value' => 'Yes'}],
                    'DefaultValues' => ['Yes']}]

  def initialize params
    self.params = params
    if params['pagination'].nil?
      # default pagination
      self.params['pagination'] = {'start' => 0, 'rows' => 20}
    end
    self.response = {}
    begin
      self.parsed_query = VirgoParser::EDS.parse(params['query']).to_h
    rescue Exception => e
      self.error_message = e.message
    end

    return unless valid_request?
    search
  end

  def search
    ensure_login do
      #$logger.debug "Request Params: #{params}"
      #$logger.debug "EDS Params: #{search_params}"

      if on_shelf_facet?
        return empty_response
      end

      s = search_params
      search_response = run_search s

      stats = search_response['SearchResult']['Statistics']
      total_hits = stats['TotalHits']
      search_time = stats['TotalSearchTime']

      facet_list = []
      available_facets = []

      # if facets were requested, return them; otherwise advertise available facets
      requested_facet = params['facet'].to_s
      facet_manifest = search_response['SearchResult']['AvailableFacets'] || []

      facet_manifest += DEFAULT_FACETS

      case requested_facet
      when ""
        available_facets = facet_manifest.map {|facet| {id: facet['Id'], name: facet['Label'] }}
      when "all"
        facet_list = facet_manifest
      else
        facet_list = facet_manifest.select {|facet| facet['Id'] == requested_facet}
      end

      records = []
      if params['pagination']['rows'].to_i > 0
        records = search_response['SearchResult']['Data']['Records'] || []
      end

      confidence = 'medium'
      if total_hits == 1
        confidence = 'exact'
      end

      self.response = {
        record_list: records,
        pagination: params['pagination'].merge(total: total_hits),
        available_facets: available_facets,
        facet_list: facet_list,
        default_facets: DEFAULT_FACETS,
        confidence: confidence,
        debug: {eds_time: search_time}
      }.deep_symbolize_keys

    end
  end
  def run_search query
    search_response = self.class.get('/edsapi/rest/Search',
                                     query: query,
                                     headers: auth_headers)
    check_session search_response
    $logger.debug search_response['SearchRequestGet']
    search_response
  end

  private
  def search_params
    facet_filter = get_facets
    query = parsed_query.merge(
      { facetfilter: facet_filter,
        # includefacets might need to be optional
        includefacets: 'y',
        searchmode: 'all',
        resultsperpage: params['pagination']['rows'],
        sort: 'relevance',
        view: 'detailed',
        highlight: 'n',
        includeimagequickview: 'y',
        # Peer reviewed limiter
        limiter: peer_reviewed_limiter
    })
    query.delete_if {|k, v| v.blank? }
    query
  end

  def get_facets
    params['filters'] ||= []
    filters = params['filters'].reject do |filter|
      # Remove these from EDS request
      # online availability
      filter['facet_id'] == 'FacetAvailability' && filter['value'] == 'Online'

      # peer reviwed (added as limiter)
      filter['facet_id'] == 'PeerReviewedFacet'
    end

    if filters.blank?
      return nil
    end

    facet_str = "1"
    filters.each do |filter|
      facet_str += ",#{filter['facet_id']}:#{filter['value']}"
    end
    facet_str
  end

  FILTER_KEYS = ['facet_id', 'value'].freeze

  # add other validations here and follow the pattern
  def valid_request?
    unless params['query'].present?
      self.status_code = 400
      self.error_message = 'Query not present'
      return false
    end
    unless parsed_query.present?
      self.status_code = 400
      self.error_message ||= 'Query Syntax error'
      return false
    end

    if params['filters'].present?
      # Check if given keys match required FILTER_KEYS
      given_keys = params['filters'].reduce([]) {|keys, item| keys | item.keys}
      if (given_keys & FILTER_KEYS).size != FILTER_KEYS.size
        self.status_code = 400
        self.error_message = "Required filter keys are: #{FILTER_KEYS.to_sentence}"
        return false
      end
    end
    return true
  end

  def on_shelf_facet?
    params['filters'].any? do |filter|
      filter['facet_id'] == 'FacetAvailability' && filter['value'] == 'On shelf'
    end
  end

  def peer_reviewed_limiter
    peer_reviewed_facet = params['filters'].detect do |filter|
      filter['facet_id'] == 'PeerReviewedFacet'
    end
    if peer_reviewed_facet && peer_reviewed_facet['value'] == 'Yes'
      'RV:Y'
    else
      nil
    end
  end

  def empty_response
    self.response = {
      record_list: [],
      pagination: {},
      available_facets: [],
      facet_list: [],
      confidence: 'low',
      debug: {eds_time: 0}
    }.deep_symbolize_keys
  end

end
