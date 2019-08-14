json.fields do
  field = Field.new(record)
  json.array! Field::LIST do |name|
    json.merge! field.get(name)
  end
end
