class EDS::Item < EDS
  require 'virgo_parser'
  require 'active_support/core_ext/hash'

  attr_accessor :record, :id, :an, :dbid

  def initialize id
    unless id.present?
      self.error_message = 'ID is required.'
      return
    end
    self.id = id
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

      search_response = self.class.get('/edsapi/rest/Retrieve',
                                       query: query,
                                       headers: auth_headers)
      check_session search_response

      r = search_response.dig 'Record'

      self.record = r.deep_symbolize_keys
    end
  end
end
