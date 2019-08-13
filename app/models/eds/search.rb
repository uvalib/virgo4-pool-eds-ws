class EDS::Search < EDS
  require 'virgo_parser'

  attr_accessor :response, :params

  def initialize params
    self.params = params
    if params['pagination'].nil?
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




      self.response = {}

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
