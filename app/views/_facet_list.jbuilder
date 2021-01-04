json.id facet[:Id]
#TODO translate
json.name facet[:Label].titleize if facet[:Label].present?
json.type facet[:Type] if facet[:Type].present?
json.buckets facet[:AvailableFacetValues] do |facet_bucket|
  json.value EDS::FacetList::PRESERVE_CASE.include?(facet[:Id]) ? facet_bucket[:Value] : facet_bucket[:Value].titleize if facet_bucket[:Value].present?
  json.count facet_bucket[:Count]
  # Check entire facet not selected, or drill down
  json.selected facet[:NotSelected] ? false : facet_bucket[:Selected]
end
