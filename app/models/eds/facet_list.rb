class EDS::FacetList < EDS

  # This list of facets will not have the case of their values modified
  # EDS requires the case to match, sometimes
  PRESERVE_CASE = %w(ContentProvider).freeze

  def initialize params
    self.facets_only = true
    super params
    return if self.error_message

    params['pagination'] = {'start' => 0, 'rows' => 1}
    facets
  end

  def facets
    if on_shelf_facet?
      return empty_facet_response
    end
    ensure_login do

      s = search_params
      search_response = run_search s

      search_time = search_response.dig 'SearchResult', 'Statistics', 'TotalSearchTime'

      facet_manifest = search_response['SearchResult']['AvailableFacets'] || []

      facet_manifest << PEER_REVIEWED_FACET.deep_dup

      # Add requested filters in
      facet_manifest = merge_requested_facets(facet_manifest)

      facet_Manifest = facet_manifest.map do |facet|

        # Mark selected Facets
        facet_selected = requested_filters.detect do |requested_f|
          facet['Id'] == requested_f['facet_id']
        end
        if facet_selected
          facet['AvailableFacetValues'].each do |f_value|
            selected = requested_filters.detect do |requested|
              requested['value'] == f_value['Value']
            end
            if selected
              f_value['Selected'] = true
            else
              f_value['Selected'] = false
            end
          end
        else
          # mark the entire facet as not selected to reduce searching
          facet['NotSelected'] = true
        end
      end

      sort_facets facet_manifest

      self.response = {
        facet_list: facet_manifest,
        debug: {eds_time: search_time}
      }.deep_symbolize_keys
    end
  end

  PASSTHROUGH_FILTERS = [{'FilterAvailability' => 'Online'}]
  def merge_requested_facets facet_manifest
    # For some facets (not sure why), EDS does not include the selected facet in the returned list. Add them back here.
    # check each requested filter
    requested_filters.each do |requested_f|
      formatted_option = {"Value" => requested_f['value'] , 'selected' => true }
      # if this facet is in the manifest
      if facet = facet_manifest.find {|fm| fm['Id'] == requested_f['facet_id']}
        # if the value does not exist
        if facet['AvailableFacetValues'].none? {|fv| fv['Value'].downcase == requested_f['value'].downcase}
          #add the bucket value
          facet['AvailableFacetValues'].unshift formatted_option
        end

      # Include these filters even though EDS doesn't use them.
      # They must start with "Filter" so they can be removed from the eds query
      elsif PASSTHROUGH_FILTERS.include?({requested_f['facet_id'] => requested_f['value']})
        # add the facet
        facet_manifest << {"Id" => requested_f['facet_id'],
                            "Label" => requested_f['facet_id'],
                            "AvailableFacetValues" => [formatted_option]
        }
      end
    end
    facet_manifest
  end

  private

  def sort_facets facet_manifest
    # ABC sort facets, move some to the top
    facet_manifest.sort_by! do |f|
      if f['Id'] == 'PeerReviewedOnly'
        '0'
      elsif f['Id'] == 'FilterAvailability'
        '1'
      else
        f['Label']
      end
    end
  end

  def empty_facet_response
    self.response = {
      facet_list: [],
      debug: {eds_time: 0}
    }.deep_symbolize_keys
  end
end
