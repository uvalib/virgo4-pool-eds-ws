module EDS::Connection
  require 'benchmark'
  require 'httparty'
  include HTTParty
  base_uri ENV['EDS_BASE_URI']
  format :json
  default_timeout 10
  #debug_output $stdout

  attr_accessor :error_message, :status_code

  def lock
    @@lock ||= Concurrent::ReentrantReadWriteLock.new
  end
  def session_token
    lock.with_read_lock {@@session_token ||= nil}
  end
  def guest_session_token
    lock.with_read_lock {@@guest_session_token ||= nil}
  end

  def login
    lock.with_write_lock do

      $logger.debug 'EDS Login'

      session = self.class.post('/edsapi/rest/CreateSession',
                  body: {'Profile' => ENV['EDS_PROFILE'],
                         'Guest' => 'n',
                         'Org' => ENV['EDS_ORG']
                        }.to_json,
                  headers: base_headers, max_retries: 0
      )
      if session.success?
        @@session_token = session['SessionToken']
      else
        $logger.error "Unable to get EDS Session Token: #{session.inspect}"
      end

      guest_session = self.class.post('/edsapi/rest/CreateSession',
                  body: {'Profile' => ENV['EDS_PROFILE'],
                         'Guest' => 'y',
                         'Org' => ENV['EDS_ORG']
                        }.to_json,
                  headers: base_headers, max_retries: 0
                               )
      @@guest_session_token = guest_session['SessionToken']
      if guest_session.success?
        @@guest_session_token = guest_session['SessionToken']
      else
        $logger.error "Unable to get EDS Session Token: #{guest_session.inspect}"
      end
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
      'x-sessionToken' => session_token
    }
  end
  def guest_auth_headers
    { 'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'x-sessionToken' => guest_session_token
    }
  end

  def ensure_login
    begin
      if session_token.nil?
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
      if e.message == 'retry'
        # catch a stale session?
        $logger.debug 'Retrying API call'
        return yield
      elsif e.message == 'Net::ReadTimeout'
        $logger.error e.message
        self.error_message = "The connection to EBSCO has timed out. Please try again later."
        self.status_code = 408
      else
        self.error_message = e.message
        self.status_code = 500
        $logger.error e.message
      end
    end
  end

  # EDS error codes: http://edswiki.ebscohost.com/API_Reference_Guide:_Error_Codes
  INVALID_SESSION_CODES = %w(104 108 109 113 141).freeze
  NOT_FOUND_CODES = %w(132 135).freeze
  MAX_RECORD_LIMIT_CODES = %w(139 138).freeze

  def check_session response
    response_code = response.code.to_s
    self.status_code = response_code
    case response_code
    when /4\d\d/
      $logger.error "#{response.code} code received from EDS \nQuery:\n#{response.request.inspect}\n\nResponse:\n#{response.body}"

      eds_error_code = response['ErrorNumber']
      if INVALID_SESSION_CODES.include? eds_error_code
        # session timeout
        login
        raise 'retry'
      elsif NOT_FOUND_CODES.include? eds_error_code
        self.status_code = 404
        raise 'Record not found'
      elsif MAX_RECORD_LIMIT_CODES.include? eds_error_code
        raise "The vendor limits access to search results from this query to the first 250.  Please try a more specific search if you're not finding what you're looking for in the first few pages."
      else
        raise 'Error from EBSCO: ' + (response.parsed_response["DetailedErrorDescription"] || response.body)
      end

    when /5\d\d/
      $logger.error '5xx code received from EDS ' + response.body
      raise response.body
    end
  end
end
