class User
  require 'benchmark'
  require 'httparty'
  include HTTParty
  base_uri ENV['V4_CLIENT_URL']
  format :json
  default_timeout 10
  #debug_output $stdout

  attr_accessor :default_peer_review, :token, :is_guest, :claims, :client_preferences, :user_id
  def initialize(token)
    return if token.nil?
    self.token = token
    process_token
    self.is_guest = !claims['isUva']
    self.user_id = claims['userId']

    get_client_preferences
    self.default_peer_review = client_preferences['defaultPeerReviewedArticles'] || false
    return self
  end

  def process_token
    begin
      token = self.token.match(/^Bearer\s+(.*)$/).captures.first
      self.claims = Rack::JWT::Token.decode(token, ENV['V4_JWT_KEY'], true, { algorithm: 'HS256' }).first
    rescue RuntimeError => e
      $logger.debug "JWT Token decode failed: #{e.message}"
      self.claims = {}
    end
  end

  def get_client_preferences
    self.client_preferences = {}
    return if self.user_id.nil? || self.user_id == 'anonymous'
    #$logger.debug "Looking up user preferences for #{self.user_id}"

    begin
      user_resp = self.class.get("/api/users/#{self.user_id}/preferences", headers: {Authorization: self.token})
      if user_resp.success?
        self.client_preferences = user_resp.parsed_response
      else
        $logger.error "Failed User preferences response: #{user_resp.body}"
      end
    rescue => ex
      $logger.error "#{ex.backtrace.join("\n\t")}"
    end
  end
end
