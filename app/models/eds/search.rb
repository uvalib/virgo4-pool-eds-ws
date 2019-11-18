class EDS::Search < EDS
  require 'virgo_parser'
  require 'active_support/core_ext/hash'

  attr_accessor :response, :params, :parsed_query, :facets_only, :requested_filters

  def initialize params
    self.params = params
    self.facets_only = params.delete 'facets_only'
    self.requested_filters = params['filters'] || []

    if params['pagination'].nil?
      # default pagination
      self.params['pagination'] = {'start' => 0, 'rows' => 20}

    elsif facets_only
      params['pagination'] = {'start' => 0, 'rows' => 0}
    end

    self.response = {}
    begin
      self.parsed_query = VirgoParser::EDS.parse(params['query']).to_h
    rescue Exception => e
      self.error_message = e.message
    end

    return unless valid_request?
    if facets_only
      facets
    else
      search
    end
  end

  DEFAULT_FACETS= [{facet_id: 'PeerReviewedFacet', name: 'Peer Reviewed Only', values: ['Yes', 'No']}]
  def self.new_facets params
    params['facets_only'] = true
    new params
  end

  def facets
    ensure_login do
      s = search_params
      search_response = run_search s

      search_time = search_response.dig 'SearchResult', 'Statistics', 'TotalSearchTime'

      facet_manifest = search_response['SearchResult']['AvailableFacets'] || []
      # Mark selected Facets
      facet_Manifest = facet_manifest.map do |facet|
        facet_selected = requested_filters.detect do |requested_f|
          facet['Id'] == requested_f['facet_id']
        end
        if facet_selected
          facet['AvailableFacetValues'].each do |f_value|
            selected = requested_filters.detect do |requested|
              requested['value'] == f_value['Value']
            end
            if selected
              f_value['Selected'] = true
            else
              f_value['Selected'] = false
            end
          end
        else
          # mark the entire facet as not selected to reduce searching
          facet['NotSelected'] = true
        end
      end

      self.response = {
        facet_list: facet_manifest,
        debug: {eds_time: search_time}
      }.deep_symbolize_keys
    end
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
        includefacets: (self.facets_only ? 'y' : 'n'),
        searchmode: 'all',
        resultsperpage: params['pagination']['rows'],
        sort: 'relevance',
        view: 'detailed',
        highlight: 'n',
        includeimagequickview: 'y',
        # Peer reviewed limiter
        limiter: 'RV:Y'
    })
    query.delete_if {|k, v| v.blank? }
    query
  end

  def get_facets
    filters = self.requested_filters.reject do |filter|
      # remove online availability from EDS request
      filter['facet_id'] == 'FacetAvailability' && filter['value'] == 'Online'
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
    if params['filters'].present?
      params['filters'].any? do |filter|
        filter['facet_id'] == 'FacetAvailability' && filter['value'] == 'On shelf'
      end
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
