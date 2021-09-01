require 'erb'

module Jekyll

  module Helpers

    def jekyll_tagging_slug(str)
      str.to_s.downcase.gsub(/\s/, '-')
    end

  end

  class Tagger < Generator

    include Helpers

    safe true

    attr_accessor :site

    @types = [:page, :feed]

    class << self; attr_accessor :types, :site; end

    def generate(site)
      self.class.site = self.site = site

      generate_tag_pages
    end

    private

    # Generates a page per tag and adds them to all the pages of +site+.
    # A <tt>tag_page_layout</tt> have to be defined in your <tt>_config.yml</tt>
    # to use this.
    def generate_tag_pages
      active_tags.each { |tag, posts| new_tag(tag, posts) }
    end

    def new_tag(tag, posts)
      self.class.types.each { |type|
        if layout = site.config["tag_#{type}_layout"]
          data = { 'layout' => layout, 'posts' => posts, 'tag' => tag, 'title' => tag }
          data.merge!(site.config["tag_#{type}_data"] || {})

          filename = yield data if block_given?
          filename ||= tag
          filename = jekyll_tagging_slug(filename)

          tag_dir = site.config["tag_#{type}_dir"]
          tag_dir = File.join(tag_dir, (pretty? ? filename : ''))

          page_name = "#{pretty? ? 'index' : filename}#{site.layouts[data['layout']].ext}"

          site.pages << TagPage.new(
            site, site.source, tag_dir, page_name, data
          )
        end
      }
    end

    def active_tags
      classifications = site.data['topics']
      # classifications.reject! { |k, v| k == 'cases'}
      all_topics = []
      classifications.each { |t, ts| all_topics.concat(ts) }

      if site.config['ignored_topics']
        all_topics.reject! { |k, v| site.config['ignored_topics'].include? k }
      end

      output = {}

      all_topics.each do |topic|
        pages = []

        site.pages.each do |pg|
          next unless pg.data.key?('tags')
          if pg.data['tags'].include?(topic)
            pages.push(pg)
          end
        end
        output[topic] = pages
      end

      output
    end

    def pretty?
      @pretty ||= (site.permalink_style == :pretty || site.config['tag_permalink_style'] == 'pretty')
    end

  end

  class TagPage < Page

    def initialize(site, base, dir, name, data = {})
      self.content = data.delete('content') || ''
      self.data    = data

      super(site, base, dir[-1, 1] == '/' ? dir : '/' + dir, name)
    end

    def read_yaml(*)
      # Do nothing
    end

  end

  module TaggingFilters

    include Helpers

    def tag_link(tag, url = tag_url(tag), html_opts = nil)
      html_opts &&= ' ' << html_opts.map { |k, v| %Q{#{k}="#{v}"} }.join(' ')
      %Q{<a href="#{url}"#{html_opts}>#{tag}</a>}
    end

    def tag_url(tag, type = :page, site = Tagger.site)
      url = File.join('', site.config["baseurl"].to_s, site.config["tag_#{type}_dir"], ERB::Util.u(jekyll_tagging_slug(tag)))
      site.permalink_style == :pretty || site.config['tag_permalink_style'] == 'pretty' ? url << '/' : url << '.html'
    end

    def active_tag_data(site = Tagger.site)
      return site.config['tag_data'] unless site.config["ignored_topics"]
      site.config["tag_data"].reject { |tag, set| site.config["ignored_topics"].include? tag }
    end
  end

end

Liquid::Template.register_filter(Jekyll::TaggingFilters)
