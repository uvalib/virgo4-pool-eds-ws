module FieldHelpers
  include I18nHelper

  # calls the method for each entry in FIELD_NAMES and add it to list
  # also handles multivalued fields
  def generate_list
    Field::FIELD_NAMES.each do |name|
      f = get name
      if f.is_a? Array
        f.each do |multi_field|
          add_to_list(multi_field)
        end
      else
        add_to_list(f)
      end
    end
  end

  def add_to_list f
    if f.present? && f[:value].present?
      self.list << f
    end
  end

  # Sends the method name
  def get name
    send(name)
  rescue NoMethodError => e
#    $logger.debug "#{e.message} - #{e.backtrace.first}"
    nil
  end



  def basic_text
    {visibility: 'basic', type: 'text'}
  end

  def detailed_text
    {visibility: 'detailed', type: 'text'}
  end

  def basic_url
    {name: 'access_url', label: t('fields.access_online'), visibility: 'basic', type: 'url'}
  end
  def detailed_url
    {visibility: 'detailed', type: 'url'}
  end
  def detailed_subjects
    {visibility: 'detailed', type: 'subject'}
  end
  def optional_field
    {display: 'optional'}
  end

  # From https://github.com/ebsco/edsapi-ruby/blob/master/lib/ebsco/eds/record.rb#L847
  def get_item_data options

    if items.blank?
      nil
    else

      if options[:name] and options[:label] and options[:group]

        items.each do |item|
          if item[:Name] == options[:name] && item[:Label] == options[:label] && item[:Group] == options[:group]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:name] and options[:label]

        items.each do |item|
          if item[:Name] == options[:name] && item[:Label] == options[:label]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:name] and options[:group]

        items.each do |item|
          if item['Name'] == options[:name] && item[:Group] == options[:group]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:label] and options[:group]

        items.each do |item|
          if item[:Label] == options[:label] && item[:Group] == options[:group]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:label]

        items.each do |item|
          if item[:Label] == options[:label]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:name]

        items.each do |item|
          if item[:Name] == options[:name]
            return sanitize_data(item)
          end
        end
        return nil

      else
        nil
      end

    end
  end

  def sanitize_data data
    # Some EDS Items are html. They aren't used currently.
    return data[:Data]
  end

end
