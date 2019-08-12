class EDSSearch
  require 'virgo_parser'
  require 'httparty'
  require 'benchmark'

  include HTTParty
  base_uri ENV['EDS_BASE_URI']
  format :json

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
    ensure_login do
      search_response = self.class.get('/edsapi/rest/Info', params: {},
                                       headers: auth_headers)
      check_session search_response

      puts search_response
    end
  end

  @@lock = Mutex.new
  def login
    @@lock.synchronize do
      puts 'Logging in'
      auth = self.class.post('/authservice/rest/UIDAuth',
                             body: {'UserId' => ENV['EDS_USER'], 'Password' => ENV['EDS_PASS']}.to_json,
                             headers: base_headers
                            )

      session = self.class.post('/edsapi/rest/CreateSession',
                                body: {'Profile' => ENV['EDS_PROFILE'],
                                       'Guest' => 'n',
                                       'Org' => ENV['EDS_ORG']}.to_json,
      headers: base_headers.merge({'x-authenticationToken' => auth['AuthToken']})
                               )
      @@auth_token = auth['AuthToken']
      @@auth_timeout = Time.now + auth['AuthTimeout'].to_i
      @@session_token = session['SessionToken']
    end
  end

  def base_headers
    { 'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  def auth_headers
    { 'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'x-authenticationToken' => @@auth_token,
      'x-sessionToken' => @@session_token
    }
  end

  def ensure_login
    begin
      if !defined?(@@session_token) || old_session?
        login
      end

      response = nil
      time = Benchmark.realtime do
        response = yield
      end
      puts "EDS Response: #{time * 1000}ms"
      return response


    rescue => e
      # catch a stale login?
      if e.message == 'retry'
        puts 'Retrying API call'
        return yield
      end
      puts e
      return []

    end
  end

  def old_session?
    Time.now > @@auth_timeout
  end

  def check_session response
    if response.code == 400
      puts 'EDS session timed out'
      login
      raise 'retry'
    end
  end


end
