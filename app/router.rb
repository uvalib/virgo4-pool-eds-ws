require_relative '../config/cuba'

Cuba.define do
  on post do
    @user = User.new(req.env['HTTP_AUTHORIZATION'])
    req.params[:is_guest] = @user.is_guest

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
      @eds = EDS::Item.new id, @user.is_guest
      if @eds.error_message.present?
        res.status = @eds.status_code
        if @eds.status_code == 404
          res.headers['Content-Type'] = 'text/plain'
          res.write(@eds.error_message)
        else
          res.write({error_message: @eds.error_message}.to_json)
        end
      else
        res.write partial('single_result')
      end

    end

    on 'api/providers' do
      res.write partial('providers')
    end

    on 'version' do
      res.write partial('version')
    end
    on 'identify' do
      res.write partial("_identify")
    end
    on 'healthcheck' do
      res.write partial("healthcheck")
    end
  end
end

