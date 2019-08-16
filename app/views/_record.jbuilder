json.fields do
  field = Field.new(record)
  json.array! field.list do |data|
    json.merge! data
  end
end
