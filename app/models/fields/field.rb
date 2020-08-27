class Field
  require 'nokogiri'
  require_relative 'field_helpers'
  include FieldHelpers

  # This is the list of fields returned for each record.
  # To add a new field, append it to this list and create a method with the same name below.
  # I18n translations use this same name.
  FIELD_NAMES= %i(
    id title author published_in published_date abstract availability
    epub_url pdf_url full_text_url ebsco_url
    volume issue pages
    subject language doi
    pub_type content_provider
    image_url,
    citation_format
  ).freeze

  attr_reader :list, :record, :bib_entity, :bib_relationships, :items, :numbering
  def initialize record
    @record = record
    @bib_entity = record.dig(:RecordInfo, :BibRecord, :BibEntity) || {}
    @bib_relationships = record.dig(:RecordInfo, :BibRecord, :BibRelationships) || {}

    @numbering = []
    if @bib_relationships[:IsPartOfRelationships].present?
      @bib_relationships[:IsPartOfRelationships].select do |bib|
        @numbering = bib.dig :BibEntity, :Numbering
        break if @numbering
      end
    end
    @items = @record.dig(:Items)

    # list is the final output including multi-valued fields
    @list = []
    generate_list
  end


  # Field methods

  def id
    value = "#{record.dig(:Header, :DbId)}_#{record.dig(:Header, :An)}"
    { name: 'id', label: t('fields.id'), value: value,
      type: 'identifier', display: 'optional', citation_part: 'id'}
  end


  def title
    titles = bib_entity.dig(:Titles) || []
    main_title = titles.find {|t| t[:Type] == 'main'} || {}
    bib_title = main_title.dig :TitleFull

    item_title = get_item_data name: 'Title'

    value = bib_title || item_title || "Please sign in to see more about this article."

    basic_text.merge({name: 'title', label: t('fields.title'),
     value: value, type: 'title', citation_part: 'title'})
  end

  # EDS doesn't have subtitles
  def subtitle
    {}
  end

  def citation_format
    optional_field.merge({
      name: 'citation_format', citation_part: 'format', value: 'article'
    })
  end

  def author
    authors = bib_relationships[:HasContributorRelationships].map do |contrib|
      contrib.dig :PersonEntity, :Name, :NameFull
    end

    authors.map do |value|
      basic_text.merge({name: 'author', label: t('fields.author'),
       value: value, type: 'author', citation_part: 'author'})
    end
  end

  def abstract
    abstract = get_item_data({name: 'Abstract', label: 'Abstract'})

    basic_text.merge({name: 'abstract', label: t('fields.abstract'),
     value: abstract, citation_part: 'abstract'})
  end

  def published_in
    main_title = ''
    bib_relationships[:IsPartOfRelationships].select do |bib|
      titles = bib.dig :BibEntity, :Titles
      main_title = titles.find {|da| da[:Type] == 'main'}.dig(:TitleFull)
      break if main_title.present?
    end
    {name: 'published_in', label: t('fields.published_in'),
     value: main_title, citation_part: 'journal'}.merge(basic_text)
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
       value: value, citation_part: 'published_date'}.merge(basic_text)
    else
      {}
    end
  end

  def availability
    {name: 'availability', label: t('fields.availability'),
     value: 'Online' }.merge(basic_text)
  end

  def ebsco_url
    value = 'https://proxy01.its.virginia.edu/login?url=' + record[:PLink]
    { provider: :ebsco, value: value, citation_part: 'url'}.merge(basic_url)
  end

  def epub_url
  end
  def pdf_url
  end
  def full_text_url
    links = record.dig(:FullText, :CustomLinks)
    full_text_link = links.find {|link| link[:Category] == 'fullText'}
    url = full_text_link[:Url] if full_text_link.present?
    {provider: :serial_solutions, value: url, citation_part: 'full_text_url'}.merge(basic_url)
  end
  def image_url
    {}
  end

  # Extended fields
  def language
    langs = bib_entity.dig :Languages
    langs.map! {|l| l[:Text]}
    langs = get_item_data({name: 'Language'}) || langs
    langs.map do |lang|
      {name: 'language', label: t('fields.language'),
       value: lang, citation_part: 'language'}.merge(detailed_text)
    end
  end

  def doi
    ids = bib_entity.dig(:Identifiers) || []
    doi = ids.find{|i| i[:Type] == 'doi'}
    if doi.present?
      { name: 'doi', label: t('fields.doi'), value: doi[:Value], citation_part: 'doi'}.merge(detailed_text)
    else
      $logger.debug "Other ids found: #{ids}" if ids.present?
      {}
    end
  end

  def subject
   #subjects = get_item_data({name: 'Subject', label: 'Subject Indexing', group: 'Su'}) ||
   #  get_item_data({name: 'Subject', label: 'Subject Category', group: 'Su'}) ||
   #  get_item_data({name: 'Subject', label: 'Subject Terms', group: 'Su'}) ||
   #  get_item_data({name: 'Subject', label: 'KeyWords Plus', group: 'Su'}) ||
   #  []

    subject_groups = items.select do |item|
      item[:Group] == 'Su'
    end

    subjects = []
    subject_groups.each do |subject|
      d = CGI.unescapeHTML subject[:Data]
      document = Nokogiri::XML.fragment(d)
      subjects +=  Nokogiri::XML.fragment(d).xpath('//text()').map(&:text).reject {|s| s.length == 1}
    end

    if subjects.present?
      subjects.map do |s|
        {name: 'subject', label: t('fields.subjects'),
         value: s }.merge(detailed_subjects)
      end
    else
      {}
    end
  end

  def pub_type
    value = record.dig :Header, :PubType
    {name: 'pub_type', label: t('fields.pub_type'),
     value: value }.merge(detailed_text)
  end

  def content_provider
    value = record.dig :Header, :DbLabel
    {name: 'content_provider', label: t('fields.content_provider'),
     value: value, citation_part: 'content_provider'}.merge(detailed_text)
  end

  def volume
    vol = numbering.find {|n| n[:Type] == 'volume'}
    {name: 'volume', label: t('fields.volume'),
     value: vol[:Value], citation_part: 'volume'}.merge(detailed_text)
  end
  def issue
    issue = numbering.find {|n| n[:Type] == 'issue'}
    {name: 'issue', label: t('fields.issue'),
     value: issue[:Value], citation_part: 'issue'}.merge(detailed_text)
  end

  def pages
    pages = bib_entity.dig :PhysicalDescription, :Pagination
    pages = "#{pages[:StartPage]}-#{pages[:StartPage].to_i + pages[:PageCount].to_i}" if pages
    {name: 'pages', label: t('fields.pages'),
     value: pages, citation_part: 'pages'}.merge(detailed_text)
  end

end
