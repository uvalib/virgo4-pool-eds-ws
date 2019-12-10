class EDS
  require_relative 'eds/connection'
  include EDS::Connection
  require 'httparty'
  include HTTParty
  base_uri ENV['EDS_BASE_URI']
  format :json
end
