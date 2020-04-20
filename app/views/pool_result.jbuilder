json.identity do
  json.name t(:pool_name)
  json.summary t(:pool_summary)
  json.description t(:pool_description)
end
json.elapsed_ms @eds.response[:elapsed_ms]
json.pagination @eds.response[:pagination]

json.sort @eds.applied_sort
json.sort_options EDS::SORT_OPTIONS

json.group_list @eds.response[:record_list], partial: 'app/views/_record', as: :record
json.confidence @eds.response[:confidence]
json.debug @eds.response[:debug]
