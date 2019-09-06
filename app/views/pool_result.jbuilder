json.identity do
  json.name t(:pool_name)
  json.summary t(:pool_summary)
  json.description t(:pool_description)
end
json.elapsed_ms @eds.response[:elapsed_ms]
json.pagination @eds.response[:pagination]
json.record_list @eds.response[:record_list], partial: 'app/views/_record', as: :record
json.available_facets @eds.response[:available_facets]
json.facet_list @eds.response[:facet_list], partial: 'app/views/_facet_list', as: :facet
json.confidence @eds.response[:confidence]
json.debug @eds.response[:debug]
