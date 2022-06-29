# frozen_string_literal: true

require 'yaml'
require 'json'
require 'fileutils'

DEBUG_CEC = ENV['DEBUG_CEC'] || false
IMAGE_SLUG_PREFIX = 'jekyll-'
DEVO_REPOSITORY_ID = '5F7FC00725C0482F9353308765B9FEF8'
REPOSITORY = 'DevO_QA'
SERVER_NAME = 'ost'
CHANNEL = 'DevO_QA'
RETRY_DELAY = 5

module Jekyll
  # CEC Hooks class
  class CECHooks
    def self.debug(msg, color: 37)
      if DEBUG_CEC
        print "\033[0;#{color}m"
        puts msg + "\033[0m"
      end
    end

    ##
    ## Execute a CEC Toolkit command
    ##
    ## @param      command  The command
    ##
    def self.cec(command, repo: true)
      Dir.chdir('_cec')
      cmd = [%(cec #{command})]
      cmd.push(%(-s #{SERVER_NAME}))
      cmd.push(%(-r #{REPOSITORY})) if repo
      debug(cmd.join(' '), color: 36)
      res = `#{cmd.join(' ')}`
      Dir.chdir('..')
      res
    end

    ##
    ## Create a temporary json payload file
    ##
    ## @param      filename  [String] the base filename (with or without json extension)
    ## @param      payload   [String] JSON string to write to file
    ##
    ## @return     [String] file path of temporary file written
    ##
    def self.temp_json(filename, payload)
      FileUtils.mkdir_p('./temp')
      file = "./temp/#{filename.sub(/\.json$/, '')}.json"

      File.open(file, 'w') { |f| f.puts payload }

      file
    end

    ##
    ## Remove temp JSON files
    ##
    ## @return     { description_of_the_return_value }
    ##
    def self.clean_up_temp_files
      FileUtils.rm_rf('temp')
    end

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
      "#{IMAGE_SLUG_PREFIX}#{File.basename(image).sub(/\..{3,4}$/, '').gsub(/[^a-z0-9]/i, '-')}"
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
        { src: img[0], file: new_img, slug: slugify_image(new_img), alt: img[1] }
      else
        warn "FILE NOT FOUND: #{new_img}"
        nil
      end
    end

    ##
    ## Scan HTML for img tags and collect the source files
    ##
    ## @param      base  The page base directory
    ## @param      html  The html
    ##
    ## @return     [Array] Array of expanded image hashes
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

      new_images.delete_if(&:nil?)

      upload_images(new_images)
    end

    ##
    ## Download multiple assets
    ##
    ## @param      images  The images
    ## @param      slugs     [Array] list of slugs
    ## @param      expected  [Array] list of assets expected
    ##                       (filepaths)
    ##
    ## @return     [Hash] :existing (Array of images that
    ##             exist on server) and :missing (Array of
    ##             images that need uploading)
    ##
    def self.download_existing(images)
      return { existing: [], missing: [] } if images.empty?

      slugs = images.map { |i| i[:slug] }
      existing = []

      query = slugs.map { |slug| %(slug eq "#{slug}") }.join(' or ')
      res = cec(%(download-content -q '#{query}'))
      downloaded = res.match(/- total items to export: (?<total>\d+)/)
      debug("=== Downloaded #{downloaded['total']} assets (requested #{images.count})", color: 35)
      return { existing: [], missing: images } if downloaded['total'].to_i.zero?

      dest = res.match(/- the assets are available at (?<dir>.*?)\n/)
      meta = JSON.parse(IO.read(File.join(dest['dir'], 'contentexport', 'metadata.json')))

      type = meta['group0'][0]
      idx = 1
      while meta.key?("group#{idx}")
        id = meta["group#{idx}"][0].sub(/^#{type}:/, '')
        path = File.join(dest['dir'], 'contentexport', 'ContentItems', 'ImageAsset', 'files', id, '*')
        files = Dir.glob(path)
        filename = files[0]
        # TODO: This would be a good time to compare downloaded and existing files
        existing.concat(images.select { |image| File.basename(image[:file]) == File.basename(filename) }.map { |image| { src: image[:src], id: id, slug: image[:slug] } })
        images.delete_if { |image| File.basename(image[:file]) == File.basename(filename) }
        idx += 1
      end

      { existing: existing, missing: images }
    end

    ##
    ## Download an array of slugs
    ##
    ## @param      slugs  [Array] The slugs to download
    ##
    ## @return     [String] path to download directory (nil
    ##             if no files downloaded)
    ##
    def self.download_contents(slugs, tries = 0)
      return nil if slugs.empty?

      raise "Error downloading contents (4 tries)" if tries > 3

      query = slugs.map { |slug| %(slug eq "#{slug}") }.join(' or ')
      debug("=== Downloading contents (try #{tries + 1})", color: 35)
      res = cec(%(download-content -q '#{query}'))
      # debug(res)
      downloaded = res.match(/- total items to export: (?<total>\d+)/)
      return nil if downloaded['total'].to_i.zero?

      dest = res.match(/- the assets are available at (?<dir>.*?)\n/)
      dest['dir']
      # meta = JSON.parse(IO.read(File.join(dest['dir'], 'contentexport', 'metadata.json')))
    end

    ##
    ## Download a single content item by slug
    ##
    ## @param      slug  [String] The slug
    ##
    ## @return     [String] content item id (nil if not found)
    ##
    def self.download_content(slug)
      return nil if slug.nil? || slug.empty?

      query = %(slug eq "#{slug}")
      res = cec(%(download-content -q '#{query}'))
      debug(res, color: 30)
      downloaded = res.match(/- total items to export: (?<total>\d+)/)
      return nil if downloaded['total'].to_i.zero?

      dest = res.match(/- the assets are available at (?<dir>.*?)\n/)
      meta = JSON.parse(IO.read(File.join(dest['dir'], 'contentexport', 'metadata.json')))
      type = meta['group0'][0]
      meta['group1'][0].sub(/^#{type}:/, '')
    end

    ##
    ## Compare local image with server version to determine
    ## if it needs an update
    ##
    ## TODO: Currently nonfunctional
    ##
    ## @param      id     The identifier
    ## @param      image  The image
    ##
    ## @return     [Boolean] true if image has changed
    ##
    def self.image_modified?(id, image)
      # downloaded image will be at _cec/src/content/#{REPOSITORY}/contentexport/ContentItems/ImageAssset/files/#{id}/#{File.basename(image)}
      # do a filesize comparison?
      # how to update an existing image asset on OCM?
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
    def self.update_html_images(images, html)
      images.each do |img|
        next if img.nil?

        macro = "[!--$CEC_DIGITAL_ASSET--]#{img[:id]}[/!--$CEC_DIGITAL_ASSET--]"
        html.gsub!(img[:src], macro)
      end
      html
    end

    ##
    ## Generate JSON for an image upload
    ##
    ## @param      slug [String] The image slug
    ## @param      alt  [String] The image alt text
    ##
    ## @return     [Hash] Fields for JSON file
    ##
    def self.image_fields(slug, alt)
      {
        'short_summary' => alt
      }
    end

    ##
    ## Upload an array of images, ignoring those that
    ## already exist on server
    ##
    ## @param      images  [Array] Array of image objects
    ##                     (Hash), each item containing src,
    ##                     file, slug, and alt fields
    ##
    ## @return     [Array] array of images, each image is a
    ##             hash containing :src, :id, and :slug
    ##
    def self.upload_images(images)
      status = download_existing(images)
      debug("=== Missing #{status[:missing].count} images, uploading", color: 35) if status[:missing].count.positive?
      downloaded = status[:missing].map { |img| upload_image(img[:src], img[:file], img[:slug], img[:alt]) }.delete_if(&:nil?)

      status[:existing].concat(downloaded)
    end

    ##
    ## Upload a single image
    ##
    ## @param      source  [String] image src value
    ## @param      image   [String] file path
    ## @param      slug    [String] image slug
    ## @param      alt     [String] alt text
    ##
    ## @return     [Hash] :src, :id, :slug
    ##
    def self.upload_image(source, image, slug, alt)
      # existing = download_content(slug)

      # return { src: source, id: existing, slug: slug } unless existing.nil?
      debug("=== Uploading #{image}", color: 35)

      temp_json('imageFields', image_fields(slug, alt).to_json)

      res = cec(%(create-digital-asset -f "../#{image}" -a ../temp/imageFields.json -t ImageAsset -g en -l "#{slug}"))

      success = res.match(/created ImageAsset asset \((.*?)\)/)

      raise "Error uploading #{image}" if success.nil?

      matches = success[1].scan(/(\w+): (\S+)/)

      data = {}
      matches.each { |m| data[m[0]] = m[1] }

      clean_up_temp_files

      { src: source, id: data['Id'], slug: data['slug'] }
    end

    ##
    ## Generate hash for empty article JSON payload
    ##
    ## @param      title  [String] Article title
    ## @param      slug   [String] Article slug
    ##
    ## @return     [Hash] values for JSON payload
    ##
    def self.empty_article_payload(title, slug)
      {
        'name' => title,
        'type' => 'DEVO_GitHub-Technical-Content',
        'description' => '',
        'repositoryId' => DEVO_REPOSITORY_ID,
        'slug' => slug,
        'language' => 'en',
        'translatable' => true,
        'fields' => {
          'html' => 'DEFINE'
        }
      }
    end

    ##
    ## Creates an empty article.
    ##
    ## @param      title [String] Article title
    ## @param      slug  [String] Article slug
    ##
    def self.create_empty_article(title, slug)
      debug("=== Creating empty article", color: 35)
      temp_json('uploadPayload', empty_article_payload(title, slug).to_json)
      cec(%(execute-post "/content/management/api/v1.1/items" -b ../temp/uploadPayload.json), repo: false)
      clean_up_temp_files
      sleep 5
    end

    ##
    ## @brief      Locate the JSON file for a downloaded
    ##             article
    ##
    ## @param      slug    [String] Article slug
    ## @param      images  [Array] Article images
    ## @param      tries   [Integer] number of tries
    ##                     attempted
    ##
    ## @return     [Array] base directory and article JSON
    ##             path
    ##
    def self.get_article_data(slug, images, tries)
      raise "Error downloading #{slug}" if tries > 3

      # NOTE: Can check slugs.count against download_contents /-
      # total items: \d/ to determine if all requested items
      # were downloaded
      slugs = [slug].concat(images.map { |img| img[:slug] })
      tries = 0
      existing = download_contents(slugs, tries)
      while existing.nil?
        tries += 1
        sleep RETRY_DELAY
        existing = download_contents(slugs, tries)
      end
      raise 'Error downloading article' if existing.nil?

      path = File.join(existing, 'contentexport', 'ContentItems', 'DEVO_GitHub-Technical-Content', '*.json')
      [existing, Dir.glob(path)[0]]
    end

    ##
    ## Create an article on the server
    ##
    ## @param      title   [String] The title
    ## @param      slug    [String] The slug
    ## @param      html    [String] The html
    ## @param      images  [Array] The images
    ##
    def self.create_article(title, slug, html, images)
      create_empty_article(title, slug) if download_content(slug).nil?
      tries = 0
      base, article = get_article_data(slug, images, tries)
      while article.nil?
        tries += 1
        debug("=== Failed to download article, trying again in #{RETRY_DELAY} seconds", color: 31)
        sleep RETRY_DELAY # attempt to handle article not being available for download immediately
        base, article = get_article_data(slug, images, tries)
      end
      data = JSON.parse(IO.read(article))

      data['fields']['html'] = html
      article_id = data['id']
      File.open(article, 'w') { |f| f.puts data.to_json }

      path = File.join(base, 'contentexport', 'metadata.json')
      data = JSON.parse(IO.read(path))

      data['groups'].to_i.times do |x|
        data.delete("group#{x}")
      end

      data['groups'] = 2
      data['group0'] = if images.count.positive?
                         %w[DEVO_GitHub-Technical-Content ImageAsset']
                       else
                         ['DEVO_GitHub-Technical-Content']
                       end

      assets = images.map { |img| "ImageAsset:#{img[:id]}" }
      assets.push("DEVO_GitHub-Technical-Content:#{article_id}")
      data['group1'] = assets

      File.open(path, 'w') { |f| f.puts data.to_json }
      pwd = Dir.pwd
      Dir.chdir(base)
      `zip -r payload.zip *`
      Dir.chdir(pwd)
      payload = File.join(base, 'payload.zip')
      res = cec(%(upload-content #{payload} -f -u -c #{CHANNEL}))
      if res =~ /file payload\.zip deleted permanently/
        debug("=== Successfully uploaded #{slug}", color: 32)
      else
        debug("=== FAIL to create #{slug}", color: '1;31')
      end
    end

    # Post-render hook activates after each page is rendered
    Jekyll::Hooks.register :pages, :post_render do |page|
      if page.data['parent']
        slug = slugify(page)
        slug = "jekyll-article-#{slug}"
        title = page.data['title']
        debug("===== Rendering #{slug} (#{title})", color: 33)
        if published?(page)
          html = page.output
          images = gather_images(page.dir, html)
          html = update_html_images(images, html)
          debug("=== Creating article #{slug} with #{images.count} images", color: 35)
          create_article(title, slug, html, images)
        else
          debug("=== Not published, archiving #{slug}", color: 35)
          # TODO: Archive page if unpublished
        end
        # TODO: Clean up cec/src/content/DevO_QA folder?
        debug("===== Finished #{slug}", color: 32)
      end
    end
  end
end

=begin notes
Would be really nice if it didn't take 30s to realize an article and all its images were already uploaded...
currently downloading images first, uploading missing images, then downloading page and all images again, then
uploading even if they already exist. Horribly slow.

# Jekyll

- [x] test for page.data['parent'] to determine if tutorial
- [x] test for page.data['published'] == false or page.data['draft'] == true
- [x] test for page.data['slug'], if empty generate slug from page.basename (apply to original page as slug front matter for permanence?)
- [x] modify template to output only main content block, no header or footer
- [?] if page.data['author'] is a string, look up author data in _data/authors.yml, if hash, use that (irrelevant if using page.output where it's already rendered, and could maybe use the author template to render a separate block using #render_liquid)
- [?] I forget, are we just including the sidebar in the HTML or does that need to be extracted?
- [x] modify image plugin to output simpler image tag with easily scannable paths, easy to substitute with OCM macro (remove srcset and data-*)
- [x] scan for images, output list of local paths (remove raw github url if present)
- [?] how to deal with series

# CEC Toolkit

- [x] method for generating manifests and zip files
- [x] test for existing pages/images using slugs
- [?] archive if not #published?
- [x] upload images and replace src with macro
- [x] publish html

# Jenkins

- [?] how to install CEC Toolkit and init in _cec in Jenkins job
- [?] can the Jenkins job notify me by email if an error occurs? (The script will raise an exception and jekyll should return a non-zero exit code if it does)
=end
