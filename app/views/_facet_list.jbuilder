json.id facet[:Id]
#TODO translate
json.name facet[:Label].titleize
json.type facet[:Type] if facet[:Type].present?
json.buckets facet[:AvailableFacetValues] do |facet_bucket|
  json.value facet_bucket[:Value]
  json.count facet_bucket[:Count]
  # Check entire facet not selected, or drill down
  json.selected facet[:NotSelected] ? false : facet_bucket[:Selected]
end
