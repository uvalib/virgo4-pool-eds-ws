class Identify
  class << self
    def name
      'Articles'
    end
    def description
      'The EBSCO Discovery Service'
    end
    def public_url
      ENV['VIRGO4_EDS_POOL_WS_POOL_SERVICE_URL'] || 'http://localhost:9292'
    end
  end
end
