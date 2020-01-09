class User
  include HTTParty
  base_uri ENV['CLIENT_BACKEND_URL']
  default_timeout 15

  def self.is_guest? token
    return true if !token.present?
    token = token.match(/^Bearer\s+(.*)$/).captures.first
    response = get("/api/authenticated/#{token}")

    if response.success?
      return false
    elsif response.not_found?
      return true
    else
      $logger.error "Auth check error - {response.request.uri}: #{response.inspect}"
      return true
    end
  end

  def self.healthcheck
    response = get("/healthcheck")
    if response.success?
      return [true, nil]
    else
      return [false, "Client Backend Error: #{response.request.inspect} #{response.body}"]
    end
  end
end
