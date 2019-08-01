require_relative "../config/cuba"


Cuba.define do
  on get do
    on "search" do

      @results = {test: 'woo'}
      res.write partial("search_result")
    end
  end
end
