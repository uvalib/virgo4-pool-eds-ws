json.service_url ENV['VIRGO4_EDS_POOL_WS_POOL_SERVICE_URL']
json.elapsed_ms @eds.response[:elapsed_ms]
json.pagination @eds.response[:pagination]
json.record_list @eds.response[:record_list], partial: 'app/views/_record', as: :record
json.available_facets @eds.response[:available_facets]
json.facet_list @eds.response[:facet_list], partial: 'app/views/_facet_list', as: :facet
json.confidence @eds.response[:confidence]
