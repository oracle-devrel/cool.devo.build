# frozen_string_literal: true

require 'kramdown'
require 'yaml'

IMAGE_SLUG_PREFIX = 'jekyll-'

module Jekyll
  # CEC Hooks class
  class CECHooks
    ##
    ## Get the slug for a page, adding it to the YAML if
    ## needed
    ##
    ## It's important that slugs not change once uploaded to
    ## OCM, so we generate a slug as needed from the
    ## basename of the file, and then immortalize it in the
    ## YAML
    ##
    ## @param      page  [Page] The Jekyll Page object for
    ##                   the article
    ##
    ## @return     [String] new slug
    ##
    def self.slugify(page)
      slug = ''
      if page.data['slug']
        slug = page.data['slug']
      else
        slug = page.basename
        update_yaml(page.path, 'slug', slug)
      end

      if slug =~ /^index$/
        slug = File.basename(page.url)
      else
        root = File.dirname(page.path.sub(%r{^tutorials/}, ''))
        slug = "#{root}-#{slug}" unless root == '.'
      end

      slug
    end

    ##
    ## Update the yaml in a file
    ##
    ## @param      file   [String] The file to update
    ## @param      key    [String] The key to add/update
    ## @param      value  [String] The value to assign
    ##
    def self.update_yaml(file, key, value)
      header, body = split_header(file)
      yaml = YAML.safe_load(header)
      yaml[key] = value
      File.open(file, 'w') { |f| f.puts [YAML.dump(yaml), body].join('---') }
    end

    # Used to separate YAML headers in raw Markdown file as
    # part of updating YAML
    #
    # @return     [Array] header, body
    #
    def self.split_header(file)
      raise "Invalid file: #{self}" unless File.exist? file

      parts = IO.read(self).split(/^---/)
      raise "Invalid YAML in #{self}" unless parts.count > 2

      header = parts[1]
      body = parts[2..-1].join('---')
      [header, body]
    end

    ##
    ## Create slug for image based on filename. Prefix,
    ## basename, no extension
    ##
    ## Prefix is defined in a constant at top of this file
    ##
    ## @param      image  The image name
    ##
    ## @return     [String] image slug
    ##
    def self.slugify_image(image)
      "#{IMAGE_SLUG_PREFIX}#{File.basename(image).sub(/\..{3,4}$/, '')}"
    end

    ##
    ## Test if page is draft or unpublished
    ##
    ## @param      page  [Page]  The page
    ##
    ## @return     [Boolean] true if published, false if
    ##             draft or unpublished
    ##
    def self.published?(page)
      page.data['draft'] != true && page.data['published'] != false
    end

    ##
    ## Convert a relative image path to fully qualified path
    ##
    ## @param      base  The base directory for the page
    ## @param      img   The image path
    ##
    ## @return     [Hash] file: absolute path, slug: slugified title, alt: alt description
    ##
    def self.expand_image(base, img)
      new_img = ".#{base}#{img[0].sub(%r{^https://github.com/oracle-devrel/devo.tutorials/raw/main/}, '')}"
      if File.exist?(File.expand_path(new_img))
        { file: new_img, slug: slugify_image(new_img), alt: img[1] }
      else
        warn "FILE NOT FOUND: #{new_img}"
        nil
      end
    end

    ##
    ## Scan HTML for img tags and collect the source files
    ##
    ## TODO: This should upload each image and gsub its path with OCM macro, returning HTML instead of image array
    ##
    ## @param      base  The page base directory
    ## @param      html  The html
    ##
    ## @return     [String] Updated HTML
    ##
    def self.gather_images(base, html)
      images = html.scan(/<img.*?src="(.*?)".*alt="(.*?)"/)
      new_images = images.map do |img|
        if img[0] =~ /^http/ && img[0] !~ %r{^https://github.com/oracle-devrel/devo.tutorials/raw/main/}
          nil
        else
          expand_image(base, img)
        end
      end

      upload_images(images, new_images, html)
    end

    ##
    ## Uploads an array of images, gets their macro, and
    ## replaces image urls with macros in html
    ##
    ## @param      images      [Array] the images to upload
    ## @param      new_images  [Array] array of absolute
    ##                         file paths, nil if image src
    ##                         is remote
    ## @param      html        [String] the HTML to update
    ##
    ## @return     [String] new HTML
    ##
    def self.upload_images(images, new_images, html)
      images.each.with_index do |img, idx|
        pp img
        unless new_images[idx].nil?
          # TODO: Upload image and get OCM macro using new_images[idx][:slug] and new_images[idx][:alt]
          macro = "[!--$CEC_DIGITAL_ASSET--]#{new_images[idx][:slug]}[/!--$CEC_DIGITAL_ASSET--]"
          html.gsub!(img, macro)
        end
      end
      html
    end

    # Post-render hook activates after each page is rendered
    Jekyll::Hooks.register :pages, :post_render do |page|
      if page.data['parent']
        slug = slugify(page)
        # TODO: Test for presence in OCM
        # if page exists, determine if it needs update
        if published?(page)
          html = page.output
          html = gather_images(page.dir, html)
          puts html
          Process.exit
          # TODO: Publish HTML

          # puts "---#{slug}---"
          # puts images
        else
          # TODO: Archive page if unpublished
        end
      end
    end

    # `puts page` contains just the HTML for the content area, not the fully rendered file
    # page.output contains full templated output
    # - [x] test for page.data['parent'] to determine if tutorial
    # - [x] test for page.data['published'] == false or page.data['draft'] == true
    # - [x] test for page.data['slug'], if empty generate slug from page.basename (apply to original page as slug front matter for permanence?)
    # - [x] modify template to output only main content block, no header or footer
    # - [?] if page.data['author'] is a string, look up author data in _data/authors.yml, if hash, use that (irrelevant if using page.output where it's already rendered, and could maybe use the author template to render a separate block using #render_liquid)
    # - [?] I forget, are we just including the sidebar in the HTML or does that need to be extracted?
    # - [x] modify image plugin to output simpler image tag with easily scannable paths, easy to substitute with OCM macro (remove srcset and data-*)
    # - [x] scan for images, output list of local paths (remove raw github url if present)
    #
    # # CEC Toolkit
    #
    # - [ ] method for generating manifests and zip files
    # - [ ] test for existing pages/images using slugs
    # - [ ] archive if not #published?
    # - [ ] upload images and replace src with macro
    # - [ ] publish html
    #
    # you can access the rendered html file at _site/#{page.path} by replacing .md with .html, but might need to be in a post_write hook
    #
    # page.data {"title"=>"Polyglot Application Observability", "parent"=>"tutorials", "tags"=>["graalvm"], "categories"=>["clouddev"], "thumbnail"=>"assets/polyglot-daigram-graalServer1.png", "date"=>"2021-10-31 11:33", "description"=>"Use GraalVM to leverage the PinPoint service, which allows tracing transactions and data flows between multiple software components and identifies problematic areas along with potential bottlenecks.", "author"=>{"name"=>"Amitpal Singh Dhillon", "bio"=>"Director at Oracle Labs, Product Management, Asia-Pacific & Japan. Previously, from Sourcefire, Cisco Systems, and Applied Materials."}, "mrm"=>"WWMK211125P00020", "xredirect"=>"https://developer.oracle.com/tutorials/polyglot-application-observability/"}
    # page.basename polyglot-application-observability
    # page.path tutorials/polyglot-application-observability.md
    # page.url /tutorials/polyglot-application-observability
    # page.permalink
    # page.relative_path tutorials/polyglot-application-observability.md
    # page.type pages
    # page.published? true
    # page.excerpt
    #
    # page.methods
    # excerpt
    # basename
    # extname
    # html?
    # pager
    # path
    # dir
    # url
    # permalink
    # index?
    # relative_path
    # data
    # url_placeholders
    # ext=
    # basename=
    # site
    # trigger_hooks
    # site=
    # excerpt_separator
    # name
    # generate_excerpt?
    # data=
    # template
    # content
    # output
    # name=
    # content=
    # inspect
    # render
    # output=
    # destination
    # write?
    # dir=
    # process
    # pager=
    # ext
    # redirect_to
    # redirect_from
    # asset_file?
    # render_with_liquid?
    # transform
    # to_s
    # []
    # type
    # do_layout
    # write
    # published?
    # validate_data!
    # validate_permalink!
    # output_ext
    # render_liquid
    # hook_owner
    # sass_file?
    # coffeescript_file?
    # renderer
    # place_in_layout?
    # converters
    # invalid_layout?
    # to_liquid
    # render_all_layouts
    # read_yaml
    # to_yaml
    # to_json
    # taint
    # tainted?
    # untaint
    # untrust
    # untrusted?
    # trust
    # methods
    # singleton_methods
    # protected_methods
    # private_methods
    # public_methods
    # instance_variables
    # instance_variable_get
    # instance_variable_set
    # instance_variable_defined?
    # remove_instance_variable
    # instance_of?
    # kind_of?
    # is_a?
    # public_method
    # method
    # public_send
    # singleton_method
    # define_singleton_method
    # extend
    # clone
    # to_enum
    # enum_for
    # <=>
    # ===
    # =~
    # !~
    # nil?
    # eql?
    # respond_to?
    # freeze
    # object_id
    # send
    # display
    # class
    # frozen?
    # tap
    # then
    # yield_self
    # gem
    # hash
    # singleton_class
    # dup
    # itself
    # !
    # ==
    # !=
    # __id__
    # equal?
    # instance_eval
    # instance_exec
    # __send__

  #   Jekyll::Hooks.register :site, :post_render do |site, payload|
  #     content = []
  #     payload.site.pages.each do |page|
  #       # p page.data['parent']
  #       # p page.data['grand_parent']
  #       if page.relative_path =~ /\.md$/
  #         begin
  #           content.push(page.render_liquid(page.content, site.site_payload, {registers: {site: site, page: payload['page']}, strict_filters: site.config["liquid"]['strict_filters'], strict_variables: site.config["liquid"]['strict_variables'] }, page.relative_path))
  #         rescue => e
  #           # puts e
  #           # puts e.backtrace
  #           $stderr.puts "Error on #{page.data['title']}"
  #         end
  #       end
  #     end
  #     puts Kramdown::Document.new(content.join("\n")).to_html
  #   end
  end
end
