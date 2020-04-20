json.identity do
  json.partial! 'app/views/_identify'
end

json.elapsed_ms @eds.response[:elapsed_ms]
json.pagination @eds.response[:pagination]

json.sort @eds.applied_sort

json.group_list @eds.response[:record_list], partial: 'app/views/_record', as: :record
json.confidence @eds.response[:confidence]
json.debug @eds.response[:debug]
