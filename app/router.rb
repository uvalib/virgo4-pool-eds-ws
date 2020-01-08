require_relative '../config/cuba'

Cuba.define do
  on post do
    req.params[:is_guest] = User.is_guest?(req.env['HTTP_AUTHORIZATION'])

    on 'api/search/facets' do

      @facets = EDS::FacetList.new req.params
      if @facets.error_message.present?
        res.status = @facets.status_code
        res.write({error_message: @facets.error_message}.to_json)
      else
        res.write partial('facets_result')
      end
    end

    # Main Search
    on 'api/search' do

      @eds = EDS::Search.new req.params
      if @eds.error_message.present?
        res.status = @eds.status_code
        res.write({error_message: @eds.error_message}.to_json)
      else
        res.write partial('pool_result')
      end
    end
  end
  on get do
    # Single Item
    on 'api/resource/:id' do |id|
      is_guest = User.is_guest?(req.env['HTTP_AUTHORIZATION'])
      @eds = EDS::Item.new id, is_guest
      if @eds.error_message.present?
        res.status = @eds.status_code
        res.write({error_message: @eds.error_message}.to_json)
      else
        res.write partial('single_result')
      end

    end

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

