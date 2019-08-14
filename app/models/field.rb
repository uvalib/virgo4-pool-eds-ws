class Field

  # mapping of API fields to EDS names
  LIST = %i(
    id title subtitle author subject language format database preview_url link
  ).freeze

  attr_reader :record
  def initialize record
    @record = record
  end

  def get name
    send(name)
  rescue NoMethodError => e
    {}
  end

  private
  def id
    { name: 'id', type: 'text', visibility: 'basic', label: 'Identifier', value: record[:header] }
  end
  def format
    {}
  end

end
