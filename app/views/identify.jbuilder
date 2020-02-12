json.name t(:pool_name)
json.description t(:pool_description)
json.attributes Identify::ATTRIBUTES do |a|
  json.name a[:name]
  json.supported a[:supported]
end
