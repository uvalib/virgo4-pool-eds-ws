class EDS::Search < EDS
  require 'active_support/core_ext/hash'

  def initialize params
    super params
    return if self.error_message

    if params['pagination'].nil?
      # default pagination
      self.params['pagination'] = {'start' => 0, 'rows' => 20}
    end

    search
  end

  def search
    if on_shelf_facet?
      return empty_search_response
    end
    ensure_login do
      $logger.debug "Request Params: #{params}"
      $logger.debug "EDS Params: #{search_params}"

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

  private

  def empty_search_response
    self.response = {
      record_list: [],
      pagination: {},
      confidence: 'low',
      debug: {eds_time: 0}
    }.deep_symbolize_keys
  end


end
