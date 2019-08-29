json.id facet[:Id]
#TODO translate
json.name facet[:Label]
json.buckets facet[:AvailableFacetValues] do |facet_value|
  json.id facet_value[:Value]
  json.value facet_value[:Value]
  json.count facet_value[:Count]
end
