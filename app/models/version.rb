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
  end
end
