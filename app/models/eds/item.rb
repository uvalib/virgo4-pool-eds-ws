class EDS::Item < EDS
  require 'virgo_parser'
  require 'active_support/core_ext/hash'

  attr_accessor :record, :id, :is_guest, :an, :dbid

  def initialize id, is_guest
    unless id.present?
      self.error_message = 'ID is required.'
      return
    end
    self.id = id
    self.is_guest = is_guest
    self.dbid, self.an, more = id.split('_')
    if more.present? || !(an.present? && dbid.present?)
      self.status_code = 404
      self.error_message = "Invalid ID format for #{id}"
      return
    end

    find
  end

  def find
    ensure_login do

      query = { an: an, dbid: dbid,
                ebookpreferredformat: 'ebook-pdf'
      }
      auth = self.is_guest ? guest_auth_headers : auth_headers
      search_response = self.class.get('/edsapi/rest/Retrieve',
                                       query: query,
                                       headers: auth)
      check_session search_response

      r = search_response.dig 'Record'
      self.record = {}

      if self.is_guest && (r.dig('Header', 'AccessLevel').to_i <= 1)
        self.status_code = 404
        self.error_message = "You must log in to see this record."
      else
        self.record = r.deep_symbolize_keys
      end
      self.record
    end
  end
end
