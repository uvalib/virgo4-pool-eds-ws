class EDS::Search < EDS
  require 'virgo_parser'

  attr_accessor :response, :request

  def initialize params
    self.request, self.response = {}
    self.request['params'] = params
    parsed = VirgoParser::EDS.parse params['query']
    self.request['eds_query'] = parsed
    self.request['pagination'] = params['pagination']
    search
  end

  def search
    ensure_login do

      search_response = self.class.get('/edsapi/rest/Info', params: {},
                                       headers: auth_headers)
      check_session search_response


      puts search_response
    end
  end

end
