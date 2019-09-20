field = Field.new(@eds.record)
json.fields do
  json.array! field.list do |data|
    json.merge! data
  end
end
