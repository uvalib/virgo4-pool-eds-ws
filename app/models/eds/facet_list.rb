class EDS::FacetList < EDS

  # This list of facets will not have the case of their values modified
  # EDS requires the case to match, sometimes
  PRESERVE_CASE = %w(ContentProvider RangeLexile).freeze

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

  def merge_requested_facets facet_manifest
    # For some facets (not sure why), EDS does not include the selected facet in the returned list. Add them back here.
    # check each requested filter
    requested_filters.each do |requested_f|
      formatted_option = {"Value" => requested_f['value'] , 'selected' => true }

      if requested_f['facet_id'].start_with?('Filter')
        # check for Filter prefix and add modify the id if found.
        matchingFilter = facet_manifest.find {|fm| "Filter#{fm['Id']}" == requested_f['facet_id']}
        matchingFilter['Id'] = "Filter#{matchingFilter['Id']}" if matchingFilter.present?
      end

      # if this facet is in the manifest
      if facet = facet_manifest.find {|fm| fm['Id'] == requested_f['facet_id']}
        # if the value does not exist
        if facet['AvailableFacetValues'].none? {|fv| fv['Value'].downcase == requested_f['value'].downcase}
          #add the bucket value
          facet['AvailableFacetValues'].unshift formatted_option
        end

      # Add in requested facets that are not in the manifest
      # Lexile range and Publication Year sometimes aren't returned as a facet, even if it was applied
      # search_response['SearchRequestGet']['SearchCriteriaWithActions']['FacetFiltersWithAction']
      else
        facet_manifest << {"Id" => requested_f['facet_id'],
          "Label" => requested_f['facet_name'],
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
      elsif f['Id'] == 'Availability'
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
