json.facet_list @facets.response[:facet_list], partial: 'app/views/_facet_list', as: :facet
json.elapsed_ms @facets.response[:elapsed_ms]
json.debug @facets.response[:debug]
