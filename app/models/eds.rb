class EDS
  require 'benchmark'
  require 'httparty'
  include HTTParty
  base_uri ENV['EDS_BASE_URI']
  format :json

  def login
    $logger.debug 'Logging in'
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
      $logger.debug "EDS Response: #{time * 1000}"
      return response

    rescue => e
      # catch a stale login?
      if e.message == 'retry'
        $logger.debug 'Retrying API call'
        return yield
      end
      $logger.error e
      return []

    end
  end

  def old_session?
    Time.now > @@auth_timeout
  end

  def check_session response
    if response.code == 400
      $logger.debug response[:ErrorDescription] || 'EDS session timed out'
      login
      raise 'retry'
    end
  end

end
