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
      RUBY_VERSION
    end
    def git_commit
      'todo'
    end
  end
end
