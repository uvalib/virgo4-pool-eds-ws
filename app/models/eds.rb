class EDS
  require 'benchmark'
  require 'httparty'
  include HTTParty
  base_uri ENV['EDS_BASE_URI']
  format :json

  def lock
    @@lock ||= Mutex.new
  end
  def auth_token
    lock.synchronize {@@auth_token ||= nil}
  end
  def auth_timeout
    lock.synchronize {@@auth_timeout ||= nil}
  end
  def session_token
    lock.synchronize {@@session_token ||= nil}
  end

  def login
    lock.synchronize do
      $logger.debug 'Logging in'
      auth = self.class.post('/authservice/rest/UIDAuth',
                             body: {'UserId' => ENV['EDS_USER'],
                                    'Password' => ENV['EDS_PASS']
                                   }.to_json,
                             headers: base_headers
                            )

      session = self.class.post('/edsapi/rest/CreateSession',
                  body: {'Profile' => ENV['EDS_PROFILE'],
                         'Guest' => 'n',
                         'Org' => ENV['EDS_ORG']
                        }.to_json,
                  headers: base_headers.merge(
                    {'x-authenticationToken' => auth['AuthToken']})
                               )
      $logger.debug "#{auth}|#{session}"
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
      'x-authenticationToken' => auth_token,
      'x-sessionToken' => session_token
    }
  end

  def ensure_login
    begin
      if session_token.nil? || old_session?
        login
      end

      response = nil
      time = Benchmark.realtime do
        response = yield
      end
      $logger.debug "EDS Response: #{(time * 1000).round} mS"
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
    old = Time.now > auth_timeout
    $logger.debug "Session Timed Out: now:#{Time.now} timeout:#{auth_timeout}" if old
    old
  end

  INVALID_SESSION_CODES = %w(104 109 113).freeze

  def check_session response
    response_code = response.code.to_s
    case response_code
    when /4\d\d/
      $logger.debug '4xx code received from EDS' + response.body

      if INVALID_SESSION_CODES.include? response_code
        # session timeout
        login
        raise 'retry'
      end
    when /5\d\d/
      $logger.debug '5xx code received from EDS' + response.body
    end
  end

end
