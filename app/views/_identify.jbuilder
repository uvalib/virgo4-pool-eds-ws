json.name t(:pool_name)
json.description t(:pool_description)
json.mode 'record'
json.attributes Identify::ATTRIBUTES do |a|
  json.name a[:name]
  json.supported a[:supported]
end
json.sort_options EDS::SORT_OPTIONS
