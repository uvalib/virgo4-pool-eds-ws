class EDS
  require 'benchmark'
  require 'httparty'
  include HTTParty
  base_uri ENV['EDS_BASE_URI']
  format :json

  attr_accessor :errors

  def lock
    @@lock ||= Concurrent::ReentrantReadWriteLock.new
  end
  def auth_token
    lock.with_read_lock {@@auth_token ||= nil}
  end
  def session_timeout
    lock.with_read_lock {@@session_timeout ||= nil}
  end
  def session_token
    lock.with_read_lock {@@session_token ||= nil}
  end

  def login
    lock.with_write_lock do

      if defined?(@@session_timeout) && !@@session_timeout.nil? && @@session_timeout > Time.now
        $logger.debug 'Skipping Additional Login'
        return
      end
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
      @@session_timeout = Time.now + auth['AuthTimeout'].to_i
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

      search_result = nil
      time = Benchmark.realtime do
        search_result = yield
      end
      ms = (time * 1000).round
      $logger.debug "EDS Response: #{ms} ms"
      search_result[:elapsed_ms] = ms
      return search_result

    rescue => e
      # catch a stale login?
      if e.message == 'retry'
        $logger.debug 'Retrying API call'
        return yield
      else
        self.errors << e.message
        $logger.error e
      end
    end
  end

  def old_session?
    old = Time.now > session_timeout
    $logger.debug "Session Timed Out" if old
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
        # Set timeout to nil to make it through the login lock once
        lock.with_write_lock { @@session_timeout = nil }
        login
        raise 'retry'
      else
        raise response.body
      end
    when /5\d\d/
      $logger.debug '5xx code received from EDS' + response.body
      raise response.body
    end
  end

end
