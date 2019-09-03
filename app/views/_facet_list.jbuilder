json.id facet[:Id]
#TODO translate
json.name facet[:Label]
json.buckets facet[:AvailableFacetValues] do |facet_value|
  json.value facet_value[:Value]
  json.count facet_value[:Count]
end
