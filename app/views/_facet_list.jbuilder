json.name facet[:Id]
json.description facet[:Label]
json.buckets facet[:AvailableFacetValues] do |facet_value|
  json.description facet_value[:Value].titleize
  json.value facet_value[:Value]
  json.count facet_value[:Count]
end
