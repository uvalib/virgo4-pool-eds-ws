require_relative '../config/cuba'

Cuba.define do
  on get do
    on 'api/search' do
      @eds = EDS::Search.new req.params
      res.write partial("search_result")
    end
  end
  on get do
    on 'version' do
      res.write partial('version')
    end
    on 'identify' do
      res.write partial("identify")
    end
    on 'healthcheck' do
      res.write partial("healthcheck")
    end
  end
end
