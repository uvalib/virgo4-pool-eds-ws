class Identify
  class << self
    def name
      ENV['VIRGO4_EDS_POOL_WS_POOL_NAME'] || 'Articles'
    end
    def description
      ENV['VIRGO4_EDS_POOL_WS_POOL_DESCRIPTION'] || 'EBSCO Discovery Service'
    end
    def public_url
      ENV['VIRGO4_EDS_POOL_WS_POOL_SERVICE_URL'] || 'http://localhost:9292'
    end
  end
end
