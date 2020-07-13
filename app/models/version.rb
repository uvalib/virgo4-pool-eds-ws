class Version
  class << self
    def build_number
      buildtag = Dir.glob('buildtag*').first
      if buildtag
        buildtag.gsub('buildtag.','')
      else
        'unknown'
      end
    end
    def ruby_version
      ENV['RUBY_VERSION']
    end
  end
end
