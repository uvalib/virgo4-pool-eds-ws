class Field
  require_relative 'field_helpers'
  include FieldHelpers

  # This is the list of fields returned for each record.
  # To add a new field, append it to this list and create a method with the same name below.
  # I18n translations use this same name.
  FIELD_NAMES= %i(
    id doi title author subject language pub_type ebsco_url abstract published_in
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
    { name: 'id', label: t('fields.id'), value: value }
  end

  def doi
    ids = bib_entity.dig(:Identifiers) || []
    doi = ids.find{|i| i[:Type] == 'doi'}
    if doi.present?
      { name: 'doi', label: t('fields.doi'), value: doi[:Value] }.merge(detailed_text)
    else
      $logger.debug "Other ids found: #{ids}" if ids.present?
      {}
    end
  end

  def title
    titles = bib_entity.dig(:Titles) || []
    main_title = titles.find {|t| t[:Type] == 'main'} || {}
    bib_title = main_title.dig :TitleFull

    item_title = get_item_data name: 'Title'

    value = bib_title || item_title

    {name: 'title', label: t('fields.title'),
     value: value}.merge(basic_text)
  end

  # EDS doesn't have subtitles
  def subtitle
    {}
  end
  def author
    authors = bib_relationships[:HasContributorRelationships].map do |contrib|
      contrib.dig :PersonEntity, :Name, :NameFull
    end

    authors.map do |value|
      {name: 'author', label: t('fields.author'),
       value: value }.merge(basic_text)
    end
  end
  def subject
    subjects = get_item_data({name: 'Subject', label: 'Subject Indexing', group: 'Su'}) ||
      get_item_data({name: 'Subject', label: 'Subject Category', group: 'Su'}) ||
      get_item_data({name: 'Subject', label: 'KeyWords Plus', group: 'Su'}) ||
      []

    if subjects.present?
      subjects.map do |s|
        {name: 'subject', label: t('fields.subject'),
         value: s }.merge(detailed_text)
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
      {name: 'language', label: t('fields.language'),
       value: lang }.merge(detailed_text)
    end
  end
  def pub_type
    value = record.dig :Header, :PubType
    {name: 'pub_type', label: t('fields.pub_type'),
     value: value }.merge(detailed_text)
  end

  def ebsco_url
    value = record[:PLink]
    {name: 'ebsco_url', label: t('fields.ebsco_url'),
     value: value }.merge(basic_url)
  end

  def abstract
    abstract = get_item_data({name: 'Abstract', label: 'Abstract'})

    {name: 'abstract', label: t('fields.abstract'),
     value: abstract }.merge(basic_text)
  end

  def source
    source = get_item_data({name: 'TitleSource'})
    {name: 'Source', label: t('fields.source'),
     value: source }.merge(basic_text)
  end

  def published_date
    published = ''
    bib_relationships[:IsPartOfRelationships].select do |bib|
      dates = bib.dig :BibEntity, :Dates
      published = dates.find {|da| da[:Type] == 'published'}
      break if published.present?
    end
    if published.present?
      value = "#{published[:Y]}-#{published[:M]}-#{published[:D]}"
      {name: 'published_date', label: t('fields.published_date'),
       value: value }.merge(basic_text)
    else
      {}
    end

  end

end
