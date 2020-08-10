class EDS
  require 'virgo_parser'
  require_relative 'eds/connection'
  include EDS::Connection
  require 'httparty'
  include HTTParty
  base_uri ENV['EDS_BASE_URI']
  format :json
  default_timeout 10
  #debug_output $stdout

  attr_accessor :response, :params, :parsed_query, :is_guest, :facets_only, :requested_filters,
                :peer_reviewed, :applied_sort

  def initialize params
    self.response = {}
    self.is_guest = params.delete :is_guest || false
    self.params = params
    #default sort
    self.applied_sort = DEFAULT_SORT

    begin
      self.parsed_query = VirgoParser::EDS.parse(params['query']).to_h
    rescue Exception => e
      self.error_message = e.message
    end
    return unless valid_request?

    apply_defaults
  end

  def search_params
    query = parsed_query.merge(
      { facetfilter: eds_facet_string,
        # includefacets might need to be optional
        includefacets: (self.facets_only ? 'y' : 'n'),
        searchmode: 'all',
        resultsperpage: params['pagination']['rows'],
        pagenumber: ((params['pagination']['start'] / params['pagination']['rows']) + 1).floor,
        sort: converted_sort,
        view: 'detailed',
        highlight: 'n',
        includeimagequickview: (self.facets_only ? 'n' : 'y'),
        # Peer reviewed limiter
        limiter: (self.peer_reviewed ? 'RV:Y' : nil)
    })
    query.delete_if {|k, v| v.blank? }
    query
  end

  def run_search query
    auth = self.is_guest ? guest_auth_headers : auth_headers
    search_response = self.class.get('/edsapi/rest/Search',
                                     query: query,
                                     headers: auth,
                                     max_retries: 0)
    check_session search_response
    #$logger.debug search_response['SearchRequestGet']
    search_response
  end

  PEER_REVIEWED_FACET = {'Id' => 'PeerReviewedOnly', 'Label' => 'Peer Reviewed Only',
                    'AvailableFacetValues' =>[ {'Value' => 'Yes'}, {'Value' => 'No'}],
                    'Type' => 'radio'
                    }

  def eds_facet_string
    filters = self.requested_filters.reject do |filter|
      # remove online availability from EDS request
      (filter['facet_id'] == 'FacetAvailability') ||
      (filter['facet_id'] == 'FacetCirculating') ||
      # remove Peer Reviewed
      ( filter['facet_id'] == PEER_REVIEWED_FACET['Id'])
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

  SORT_OPTIONS = [
    {
      "id": "SortRelevance",
      "label": "Relevance"
    },
    {
      "id": "SortDate",
      "label": "Date Published",
      "asc": "oldest first",
      "desc": "newest first"
    }
  ]

  # Applied sort in response
  DEFAULT_SORT = {'sort_id' => 'SortRelevance', 'order' => 'desc' }

  # Converts sort param into EDS sort key
  def converted_sort
    s = params['sort']
    return if s.nil?

    if s['sort_id'] == 'SortDate' &&
      s['order'] == 'desc'
      self.applied_sort = s
      return 'date'

    elsif s['sort_id'] == 'SortDate' &&
      s['order'] == 'asc'
      self.applied_sort = s
      return 'date2'

    else
      # Relevance only has desc, also used as a catch-all
      'relevance'
    end
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
      # only one set of filters alowed
      if !params['filters'].one?
        self.status_code = 400
        self.error_message = "Only one set of filters alowed."
        return false
      end

      filters = params['filters'].first['facets']
      # Check if given keys match required FILTER_KEYS
      given_keys = filters.reduce([]) {|keys, item| keys | item.keys}
      if given_keys.include? FILTER_KEYS
        self.status_code = 400
        self.error_message = "Available filter keys are: #{FILTER_KEYS.to_sentence}"
        return false
      end
    end

    self.requested_filters = filters || []
    return true
  end

  def apply_defaults

    peer_reviewed_request = requested_filters.find do |f|
      f['facet_id'] == PEER_REVIEWED_FACET['Id']
    end

    if peer_reviewed_request.present? && peer_reviewed_request['value'] == 'No'
      self.peer_reviewed = false
    else
      self.peer_reviewed = true
      self.requested_filters << {'facet_id' => PEER_REVIEWED_FACET['Id'], 'value' => 'Yes'}
    end
  end

  def on_shelf_facet?
    if requested_filters.present?
      requested_filters.any? do |filter|
        filter['facet_id'] == 'FacetAvailability' && filter['value'] == 'On shelf'
      end
    end
  end

  def circulating_facet?
    if requested_filters.present?
      requested_filters.any? do |filter|
        filter['facet_id'] == 'FacetCirculating'
      end
    end
  end

  def merge_requested_facets facet_manifest
    requested_filters.each do |requested_f|
      formatted_f = {"Value" => requested_f['value'] , 'selected' => true }
      # if this facet is in the manifest
      if facet = facet_manifest.find {|fm| fm['Id'] == requested_f['facet_id']}
        # if the value does not exist
        if facet['AvailableFacetValues'].none? {|fv| fv['Value'] == formatted_f['Value']}
          #add the bucket value
          facet['AvailableFacetValues'] << formatted_f
        end
      else
        # add the facet
        label = requested_f['facet_name'] || requested_f['display']['facet']
        facet_manifest << {"Id" => requested_f['facet_id'],
                            "Label" => label,
                            "AvailableFacetValues" => [formatted_f]
        }
      end
    end
    facet_manifest
  end

  def self.healthcheck
    #check session variables
    healthy = true
    message = nil

    begin
      eds = EDS.new 'query' => 'title:{placeholder}'
      info = eds.info

      if info.class != HTTParty::Response || info.success? == false
        healthy = false
        message = "EDS info request failed: #{info.inspect}"
      end
    rescue Errno::ECONNREFUSED => ex
      healthy = false
      message = "EDS connection refused: #{ex}"
    rescue Net::ReadTimeout => ex
      healthy = false
      message = "EDS read timeout: #{ex}"
    rescue => ex
        healthy = false
        message = "EDS error: #{ex.class}"
        puts "#{ex.backtrace.join("\n\t")}"
    end
    [healthy, message]
  end

  def info
    # dummy request/response for testing connection
    ensure_login do
      info = self.class.get('/edsapi/rest/info', {format: 'text',
                      headers: auth_headers, max_retries: 0}
                     )
      return info
    end
    return {}
  end

end
