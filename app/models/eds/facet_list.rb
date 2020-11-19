class EDS::FacetList < EDS


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


      # Mark selected Facets
      facet_Manifest = facet_manifest.map do |facet|
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

  def merge_requested_facets facet_manifest
    # check each requested filter
    requested_filters.each do |requested_f|
      formatted_f = {"Value" => requested_f['value'] , 'selected' => true }
      # if this facet is in the manifest
      if facet = facet_manifest.find {|fm| fm['Id'] == requested_f['facet_id']}
        # if the value does not exist
        if facet['AvailableFacetValues'].none? {|fv| fv['Value'] == formatted_f['Value']}
          #add the bucket value
          facet['AvailableFacetValues'] << formatted_f
        end
      else
        # add the facet
        label = requested_f['value'] || requested_f['display']['facet']
        facet_manifest << {"Id" => requested_f['facet_id'],
                            "Label" => label,
                            "AvailableFacetValues" => [formatted_f]
        }
      end
    end
    facet_manifest
  end

  private

  def sort_facets facet_manifest
    # ABC sort facets
    facet_manifest.sort_by! do |f|
      if f['Id'] == 'PeerReviewedOnly'
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
