# frozen_string_literal: true

require 'yaml'
require 'json'
require 'fileutils'
require_relative 'colors'

DEBUG_CEC = ENV['DEBUG_CEC'] || 1
IMAGE_SLUG_PREFIX = 'jekyll-'
ARTICLE_SLUG_PREFIX = 'devo-'
DEVO_REPOSITORY_ID = '5F7FC00725C0482F9353308765B9FEF8'
REPOSITORY = 'DevO_QA'
SERVER_NAME = 'ost'
CHANNEL = 'DevO_QA'
RETRY_DELAY = 5

module Jekyll
  # CEC Hooks class
  class CECHooks
    attr_accessor :errors
    class << self
      LOG_LEVELS = %i[error warning info debug].freeze
      LOG_COLORS = {
        normal: 'boldwhite',
        start: 'boldbggreen black',
        command: 'cyan',
        console: 'boldblack',
        action: 'yellow',
        result: 'purple',
        failure: 'boldbgred boldwhite',
        warning: 'boldred',
        success: 'boldgreen',
        aux: 'magenta',
        finish: 'boldbggreen boldwhite'
      }.freeze

      def log_message(msg, type: :normal, level: :log)
        return nil unless LOG_LEVELS.index(level.to_sym) <= DEBUG_CEC.to_i

        colors = []
        LOG_COLORS[type.to_sym].split(' ').each { |c| colors.push(Color.send(c)) }

        msg = msg.split(/\n/).slice(0,20).join("\n")
        puts "#{colors.join('')}#{msg}#{Color.reset}"
        nil
      end

      def debug(msg, type: :normal)
        log_message(msg, type: type, level: :debug)
      end

      def info(msg, type: :normal)
        log_message(msg, type: type, level: :info)
      end

      def alert(msg, type: :normal)
        log_message(msg, type: type, level: :warning)
      end

      def error(msg, type: :normal)
        @errors.push(msg)
        log_message(msg, type: type, level: :error)
      end

      ##
      ## Execute a CEC Toolkit command
      ##
      ## @param      command  The command
      ##
      def cec(command, repo: true)
        Dir.chdir('_cec')
        cmd = [%(cec #{command})]
        cmd.push(%(-s #{SERVER_NAME}))
        cmd.push(%(-r #{REPOSITORY})) if repo
        debug(cmd.join(' '), type: :command)
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
      def temp_json(filename, payload)
        FileUtils.mkdir_p('./_temp')
        file = "./_temp/#{filename.sub(/\.json$/, '')}.json"

        File.open(file, 'w') { |f| f.puts payload }

        file
      end

      ##
      ## Remove temp JSON files
      ##
      ## @return     { description_of_the_return_value }
      ##
      def clean_up_temp_files
        dir = File.expand_path('_temp')
        # alert("Removing temporary dir at #{dir}", type: :warning)
        # FileUtils.rm_rf(dir)
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
      def slugify(page)
        slug = get_slug(page)

        if slug =~ /^index$/
          slug = File.basename(page.url)
        else
          root = File.dirname(page.path.sub(%r{^tutorials/}, ''))
          slug = "#{root}-#{slug}" unless root == '.'
        end

        "#{ARTICLE_SLUG_PREFIX}#{slug}"
      end

      def get_slug(page)
        slug = ''
        if page.data['slug']
          slug = page.data['slug']
        else
          slug = page.basename
          update_yaml(page.path, 'slug', slug)
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
      def update_yaml(file, key, value)
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
      def split_header(file)
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
      def slugify_image(image)
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
      def published?(page)
        page.data['draft'] != true && page.data['published'] != false && page.data['archive'] != true && page.data['archived'] != true
      end

      ##
      ## Convert a relative image path to fully qualified path
      ##
      ## @param      base  The base directory for the page
      ## @param      img   The image path
      ##
      ## @return     [Hash] file: absolute path, slug: slugified title, alt: alt description
      ##
      def expand_image(base, img)
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
      def gather_images(base, html)
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
      ## Upload a single image
      ##
      ## @param      source  [String] image src value
      ## @param      image   [String] file path
      ## @param      slug    [String] image slug
      ## @param      alt     [String] alt text
      ##
      ## @return     [Hash] :src, :id, :slug
      ##
      def upload_image(source, image, slug, alt)
        log("=== Uploading #{image}", type: :action)

        json = temp_json('imageFields', image_fields(alt).to_json)

        res = cec(%(create-digital-asset -f "../#{image}" -a ../#{json} -t ImageAsset -g en -l "#{slug}"))

        success = res.match(/created ImageAsset asset \((.*?)\)/)

        return error("Error uploading #{image}", type: :failure) if success.nil?

        image_hash(success, source)
      end

      def image_hash(success, source)
        matches = success[1].scan(/(\w+): (\S+)/)

        data = {}
        matches.each { |m| data[m[0]] = m[1] }

        clean_up_temp_files

        { src: source, id: data['Id'], slug: data['slug'] }
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
      def upload_images(images)
        status = download_existing(images)

        # log("=== Missing #{status[:missing].count} images, uploading", type: :aux) if status[:missing].count.positive?
        downloaded = status[:missing].map { |img| upload_image(img[:src], img[:file], img[:slug], img[:alt]) }
        downloaded.delete_if(&:nil?)

        status[:existing].concat(downloaded)
      end

      ##
      ## Create macros for each image and update html img tags
      ##
      ## @param      images      [Array] the images to upload
      ## @param      new_images  [Array] array of absolute
      ##                         file paths, nil if image src
      ##                         is remote
      ## @param      html        [String] the HTML to update
      ##
      ## @return     [String] new HTML
      ##
      def update_html_images(images, html)
        images.each do |img|
          next if img.nil?

          macro = "[!--$CEC_DIGITAL_ASSET--]#{img[:id]}[/!--$CEC_DIGITAL_ASSET--]"
          html.gsub!(img[:src], macro)
        end
        html
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
      def download_existing(images)
        return { existing: [], missing: [] } if images.empty?

        slugs = images.map { |i| i[:slug] }
        existing = []

        query = slugs.map { |slug| %(slug eq "#{slug}") }.join(' or ')
        res = cec(%(download-content -q '#{query}'))
        debug(res, type: :console)
        downloaded = res.match(/- total items to export: (?<total>\d+)/)
        info("=== Downloaded #{downloaded['total']}/#{images.count} assets", type: :result)
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
          # TODO: Compare downloaded images to local versions and upload if changed
          new_existing = images.select { |image| File.basename(image[:file]) == File.basename(filename) }
          existing.concat(new_existing.map { |image| { src: image[:src], id: id, slug: image[:slug] } })
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
      def download_contents(slugs, tries = 0)
        return nil if slugs.empty?

        return error('Error downloading contents (4 tries)', type: :failure) if tries > 3

        query = slugs.map { |slug| %(slug eq "#{slug}") }.join(' or ')
        info("=== Downloading contents (try #{tries + 1})", type: :action)
        res = cec(%(download-content -q '#{query}'))
        debug(res, type: :console)
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
      def download_content(slug)
        return nil if slug.nil? || slug.empty?

        query = %(slug eq "#{slug}")
        res = cec(%(download-content -q '#{query}'))
        debug(res, type: :console)
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
      def image_modified?(id, image)
        remote = [
          "_cec/src/content/#{REPOSITORY}/",
          "contentexport/ContentItems/ImageAssset/files/#{id}/",
          File.basename(image)
        ].join('')
        !remote.identical?(image)
      end

      ##
      ## Generate JSON for an image upload
      ##
      ## @param      slug [String] The image slug
      ## @param      alt  [String] The image alt text
      ##
      ## @return     [Hash] Fields for JSON file
      ##
      def image_fields(alt)
        {
          'short_summary' => alt
        }
      end

      ##
      ## Generate hash for empty article JSON payload
      ##
      ## @param      title  [String] Article title
      ## @param      slug   [String] Article slug
      ##
      ## @return     [Hash] values for JSON payload
      ##
      def empty_article_payload(title, slug)
        {
          'name' => title,
          'type' => 'DEVO_GitHub-Technical-Content',
          'description' => '',
          'repositoryId' => DEVO_REPOSITORY_ID,
          'slug' => slug,
          'language' => 'en',
          'translatable' => true,
          'fields' => { 'html' => 'DEFINE' }
        }
      end

      ##
      ## Creates an empty article.
      ##
      ## @param      title [String] Article title
      ## @param      slug  [String] Article slug
      ##
      def create_empty_article(title, slug)
        info('=== Creating empty article', type: :action)
        temp_json('uploadPayload', empty_article_payload(title, slug).to_json)
        debug(cec(%(execute-post "/content/management/api/v1.1/items" -b ../_temp/uploadPayload.json), repo: false), type: :console)
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
      def get_article_data(slug, images, tries)
        return error("Error downloading #{slug}", type: :failure) if tries > 3

        # NOTE: Can check slugs.count against download_contents /-
        # total items: \d/ to determine if all requested items
        # were downloaded
        slugs = [slug].concat(images.map { |img| img[:slug] })
        tries = 0
        existing = download_contents(slugs, tries)
        while existing.nil?
          break if tries > 3

          tries += 1
          sleep RETRY_DELAY
          existing = download_contents(slugs, tries)
        end
        return error('Error downloading article', type: :failure) if existing.nil?

        path = File.join(existing, 'contentexport', 'ContentItems', 'DEVO_GitHub-Technical-Content', '*.json')
        [existing, Dir.glob(path)[0]]
      end

      def publish_article(slug, images)
        info("=== Publishing #{slug}", type: :action)
        tries = 0
        _, article = get_article_data(slug, [], tries)
        while article.nil?
          break if tries > 3

          tries += 1
          alert("=== Publish: Failed to download #{slug}, trying again in #{RETRY_DELAY} seconds",
                type: :warning)
          sleep RETRY_DELAY # attempt to handle article not being available for download immediately
          _, article = get_article_data(slug, [], tries)
        end

        if article.nil?
          info("#{slug} doesn't exist, ignoring", kind: :result)
          return
        end

        data = JSON.parse(IO.read(article))

        query = generate_archive_query(data['id'], images)
        json = temp_json('publishPayload', { 'q' => query }.to_json)

        debug(cec(%(execute-post "/content/management/api/v1.1/bulkItemsOperations/publish" -b ../#{json}),
                  repo: false), type: :console)

        info("=== Published #{slug} and images", type: :success)
        clean_up_temp_files
      end

      def archive_article(slug, images)
        info("=== #{slug} not published, archiving", type: :action)
        return nil if download_content(slug).nil?

        tries = 2
        _, article = get_article_data(slug, [], tries)
        while article.nil?
          break if tries > 3

          tries += 1
          alert("=== Archive: Failed to download #{slug}, trying again in #{RETRY_DELAY} seconds",
                type: :warning)
          sleep RETRY_DELAY # attempt to handle article not being available for download immediately
          _, article = get_article_data(slug, [], tries)
        end

        if article.nil?
          info("#{slug} doesn't exist, ignoring", kind: :result)
          return
        end

        data = JSON.parse(IO.read(article))

        query = generate_archive_query(data['id'], images)
        json = temp_json('archivePayload', { 'q' => query }.to_json)

        debug(cec(%(execute-post "/content/management/api/v1.1/bulkItemsOperations/archive" -b ../#{json}),
                  repo: false), type: :console)

        info("=== Archived #{slug} and images", type: :success)
        clean_up_temp_files
      end

      def generate_archive_query(article_id, images)
        image_ids = images.map { |image| image[:id] }
        [article_id].concat(image_ids).map { |id| %(id eq "#{id}") }.join(' or ')
      end

      ##
      ## Create an article on the server
      ##
      ## @param      title   [String] The title
      ## @param      slug    [String] The slug
      ## @param      html    [String] The html
      ## @param      images  [Array] The images
      ##
      def create_article(title, slug, html, images)
        create_empty_article(title, slug) if download_content(slug).nil?
        tries = 0
        base, article = get_article_data(slug, images, tries)
        while article.nil?
          break if tries > 3

          tries += 1
          alert("=== Failed to download #{slug}, trying again in #{RETRY_DELAY} seconds",
                type: :warning)
          sleep RETRY_DELAY # attempt to handle article not being available for download immediately
          base, article = get_article_data(slug, images, tries)
        end
        data = JSON.parse(IO.read(article))

        if data['fields']['html'] == html
          return info("=== No change in #{slug}", type: :success)
        end

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
        debug(res, type: :console)
        if res =~ /file payload\.zip deleted permanently/
          info("=== Successfully uploaded #{slug}", type: :success)
          # FIXME: publish endpoint doesn't work, is there another one?
          # publish_article(slug, images)
        else
          error("=== FAIL to create #{slug}", type: :failure)
        end
      end
    end

    # Post-render hook activates after each page is rendered
    Jekyll::Hooks.register :pages, :post_render do |page|
      Color.coloring = $stdout.isatty
      @errors = []
      if page.data['parent']
        slug = slugify(page)
        title = page.data['title']
        info("===== Rendering #{slug} (#{title})", type: :start)
        if published?(page)
          html = page.output
          images = gather_images(page.dir, html)
          html = update_html_images(images, html)
          info("=== Creating article #{slug} with #{images.count} images", type: :action)
          create_article(title, slug, html, images)
        else
          html = page.output
          images = gather_images(page.dir, html)
          archive_article(slug, images)
          # TODO: Archive page if unpublished
        end
        # TODO: Clean up cec/src/content/DevO_QA folder?
        info("===== Finished #{slug}", type: :finish)
        if @errors.count.positive?
          puts 'ERRORS:'
          puts @errors
          raise 'Errors occurred'
        end
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
- [?] how to add author slug
- [?] does the slug I use end up being the url, or can that be controlled separately?
- [ ] does the mrm plugin need updating? Still has dotbuild in the urls

# CEC Toolkit

- [x] method for generating manifests and zip files
- [x] test for existing pages/images using slugs
- [?] archive if not #published?
- [x] upload images and replace src with macro
- [x] upload html
- [?] possible to publish via toolkit?
- [?] what to do with tags and categories?
- [?] how do I view the results on the web?
# Jenkins

- [?] how to install CEC Toolkit and init in _cec in Jenkins job
- [?] can the Jenkins job notify me by email if an error occurs? (The script will raise an exception and jekyll should return a non-zero exit code if it does)
- [?] how do you trigger a Jenkins job with a GitHub Action? Or can Jenkins watch the tutorials repo for updates itself?
=end
