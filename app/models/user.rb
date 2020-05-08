class User
  include HTTParty
  base_uri ENV['CLIENT_BACKEND_URL']
  default_timeout 10

  def self.is_guest? token
    return true if !token.present?
    begin
      token = token.match(/^Bearer\s+(.*)$/).captures.first
      claims = Rack::JWT::Token.decode(token, ENV['V4_JWT_KEY'], true, { algorithm: 'HS256' })
      v4_claims = claims.first
      #$logger.debug v4_claims

      if v4_claims['isUva']
        return false
      else
        return true
      end
    rescue RuntimeError => e
      # Should never reach this point since auth is checked at the beginning of the request
      $logger.error "JWT Token decode failed: #{e.message}"
      return true
    end
  end

  def self.healthcheck

    begin
    response = get("/healthcheck")
    if response.success?
      return [true, nil]
    else
      return [ false, "User service error: #{response.request.inspect} #{response.body}"]
    end
    rescue Errno::ECONNREFUSED => ex
      return [ false, "User service connection refused: #{ex}" ]
    rescue Net::ReadTimeout => ex
      return [ false, "User service read timeout: #{ex}" ]
    rescue => ex
      return [ false, "User service error: #{ex.class}" ]
    end
  end
end
