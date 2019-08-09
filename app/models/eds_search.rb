class EDSSearch
  require 'virgo_parser'

  def self.search params

    parsed = VirgoParser::EDS.parse params['query']
    pagination = params['pagination']

  end
end
