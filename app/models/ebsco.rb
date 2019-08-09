class EDSSearch
  require 'virgo_parser'
  attr_accessor :response, :request

  def initialize params
    self.request, self.response = {}
    self.request['params'] = params

    parsed = VirgoParser::EDS.parse params['query']
    self.request['eds_params'] = parsed
    self.request['pagination'] = params['pagination']

    search
  end

  def search


  end
end
