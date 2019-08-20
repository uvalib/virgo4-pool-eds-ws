module FieldHelpers

  # calls the method for each entry in FIELD_NAMES and add it to list
  # also handles multivalued fields
  def generate_list
    Field::FIELD_NAMES.each do |name|
      f = get name
      if f.is_a? Array
        f.each {|multi_field| self.list << multi_field }
      else
        self.list << f unless f.empty?
      end
    end
  end

  # Sends the method name
  def get name
    send(name)
  rescue NoMethodError => e
    nil
  end

  def basic_text
    {visibility: 'basic', type: 'text'}
  end

  def detailed_text
    {visibility: 'detailed', type: 'text'}
  end

  def basic_url
    {visibility: 'basic', type: 'url'}
  end
  def detailed_url
    {visibility: 'detailed', type: 'url'}
  end

  # From https://github.com/ebsco/edsapi-ruby/blob/master/lib/ebsco/eds/record.rb#L847
  def get_item_data options

    if items.empty?
      nil
    else

      if options[:name] and options[:label] and options[:group]

        items.each do |item|
          if item['Name'] == options[:name] && item['Label'] == options[:label] && item['Group'] == options[:group]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:name] and options[:label]

        items.each do |item|
          if item['Name'] == options[:name] && item['Label'] == options[:label]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:name] and options[:group]

        items.each do |item|
          if item['Name'] == options[:name] && item['Group'] == options[:group]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:label] and options[:group]

        items.each do |item|
          if item['Label'] == options[:label] && item['Group'] == options[:group]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:label]

        items.each do |item|
          if item['Label'] == options[:label]
            return sanitize_data(item)
          end
        end
        return nil

      elsif options[:name]

        items.each do |item|
          if item['Name'] == options[:name]
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
    return data
  end
end

# From https://github.com/ebsco/edsapi-ruby
class Hash
  def deep_find(key, object=self, found=[])
    if object.respond_to?(:key?) && object.key?(key)
      found << object[key]
    end
    if object.is_a? Enumerable
      found << object.collect { |*a| deep_find(key, a.last) }
    end
    found.flatten.compact
  end
end
