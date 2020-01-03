field = Field.new(record)

json.value field.id[:value]
json.count 1 # EDS does not support grouping so has groups of 1
json.has_availability false
json.record_list [1] do
  json.fields do
    json.array! field.list do |data|
      json.merge! data
    end
  end
end
