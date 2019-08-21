# Portions of this are influenced by the edsapi-ruby gem
# https://github.com/ebsco/edsapi-ruby/blob/master/lib/ebsco/eds/record.rb
class Field
  include FieldHelpers

  # mapping of API fields to EDS names
  FIELD_NAMES= %i(
    id doi title author subject language pub_type link abstract published_in
    published_date
  ).freeze

  attr_reader :list, :record, :bib_entity, :bib_relationships, :items
  def initialize record
    @record = record
    @bib_entity = record.dig(:RecordInfo, :BibRecord, :BibEntity)
    @bib_relationships = record.dig(:RecordInfo, :BibRecord, :BibRelationships)
    @items = record.dig(:Items)

    # list is the final output including multi-valued fields
    @list = []
    generate_list
  end

  private

  # Field methods

  def id
    value = "#{record.dig(:Header, :DbId)}_#{record.dig(:Header, :An)}"
    { name: 'id', label: 'Identifier', value: value }.merge(detailed_text)
  end

  def doi
    ids = bib_entity.dig(:Identifiers) || []
    doi = ids.find{|i| i[:Type] == 'doi'}
    if doi.present?
      { name: 'doi', label: 'DOI', value: doi[:Value] }.merge(detailed_text)
    else
      $logger.debug "Other ids found: #{ids}"
      {}
    end
  end

  def title
    titles = bib_entity.dig(:Titles) || []
    main_title = titles.find {|t| t[:Type] == 'main'} || {}
    bib_title = main_title.dig :TitleFull

    item_title = get_item_data name: 'Title'

    value = bib_title || item_title

    {name: 'title', label: 'Title',
     value: value}.merge(basic_text)
  end

  # EDS doesn't have subtitles
  def subtitle
    {}
  end
  def author
    authors = bib_relationships.deep_find :NameFull
    authors.map do |value|
      {name: 'author', label: 'Author',
       value: value }.merge(basic_text)
    end
  end
  def subject
    subjects = get_item_data({name: 'Subject', label: 'Subject Indexing', group: 'Su'}) ||
      get_item_data({name: 'Subject', label: 'Subject Category', group: 'Su'}) ||
      get_item_data({name: 'Subject', label: 'KeyWords Plus', group: 'Su'}) ||
      bib_entity.deep_find(:SubjectFull) || []

    if subjects.present?
      if subjects.is_a? Array
        subjects.map do |s|
          {name: 'subject', label: 'Subject',
           value: s }.merge(detailed_text)
        end

      else
        {name: 'subject', label: 'Subject',
         value: subjects }.merge(detailed_text)
      end
    else
      {}
    end
  end

  def language
    langs = bib_entity.dig :Languages
    langs.map! {|l| l[:Text]}
    langs = get_item_data({name: 'Language'}) || langs
    langs.map do |lang|
      {name: 'language', label: 'Language',
       value: lang }.merge(detailed_text)
    end
  end
  def pub_type
    value = record.dig :Header, :PubType
    {name: 'pub_type', label: 'Publication Type',
     value: value }.merge(detailed_text)
  end

  def link
    value = record[:PLink]
    {name: 'ebsco_url', label: 'More',
     value: value }.merge(basic_url)
  end

  def abstract
    abstract = get_item_data({name: 'Abstract', label: 'Abstract'})

    {name: 'abstract', label: 'Abstract',
     value: abstract }.merge(basic_text)
  end

  def source
    source = get_item_data({name: 'TitleSource'})
    {name: 'Source', label: 'Source',
     value: source }.merge(basic_text)
  end
  def published_date
    dates = bib_relationships.deep_find :Dates
    published = dates.find {|da| da[:Type] == 'published'}
    if published.present?
      value = "#{published[:Y]}-#{published[:M]}-#{published[:D]}" 
      {name: 'published_date', label: 'Published Date',
       value: value }.merge(basic_text)
    else
      {}
    end

  end

end
