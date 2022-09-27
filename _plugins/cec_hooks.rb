# frozen_string_literal: true

REPOSITORY = 'DevO_QA'
SERVER_NAME = 'ost'
CHANNEL = 'DevO_QA'
IMAGE_SLUG_PREFIX = 'jekyll-'
ARTICLE_SLUG_PREFIX = 'devo-'

require 'yaml'
require 'json'
require 'fileutils'
require 'html_press'
require 'io/console' unless IO.method_defined?(:winsize)
require 'tty-screen'
require 'tty-which'

require_relative 'colors'
require_relative 'logger'
require_relative 'cec_util'
# Must set the CEC_DEPLOY environment variable to trigger
# `CEC_DEPLOY=true bundle exec jekyll build`

# Run Jekyll with DEBUG_CEC set to 0-3 for logging.
# 0 = no messages, 3 = all messages (debug)
# `CEC_DEPLOY=true DEBUG_CEC=3 bundle exec jekyll build`

# Script will skip any articles that cause an error and
# report all errors at the end of the run. If there are any
# errors, an exception will be raised and Jekyll will exit
# non-zero.

DEBUG_CEC = ENV['DEBUG_CEC'] || 1
RETRY_DELAY = 5

module Jekyll
  # CEC Hooks class
  class CECHooks
    attr_accessor :images

    class << self
      include Util
      ##
      ## Execute a CEC Toolkit command
      ##
      ## @param      command  The command
      ##
      def cec(command, repo: true)
        operation = command.match(/^(\S+) /)[1]
        Util.clock(:operation, :start)
        Dir.chdir(File.join(Util.pwd, '_cec'))
        cmd = [%(cec #{command})]
        cmd.push(%(-s #{SERVER_NAME}))
        cmd.push(%(-r #{REPOSITORY})) if repo
        debug("> #{cmd.join(' ')}", type: :command)
        res = `#{cmd.join(' ')}`
        debug(border(res), type: :console)
        Dir.chdir(Util.pwd)
        Util.clock(:operation, :finish)
        Util.print_bench(:operation, title: "#{operation} completed in", border: false, level: :debug)
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
        # alert("Removing temporary dir at #{dir}", type: :aux)
        FileUtils.rm_rf(dir)
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
          slug = "#{root}_#{slug}" unless root == '.'
        end

        "#{ARTICLE_SLUG_PREFIX}#{slug}"
      end

      ##
      ## This method is called by #slugify and should not be
      ## called directly
      ##
      ## @param      page  [Page] The Jekyll page object
      ##
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
      ## Create slug for image based on filename. Prefix,
      ## basename, no extension
      ##
      ## Prefix is defined in a constant at top of this file
      ##
      ## @param      image  [String] The image filename
      ##
      ## @return     [String] image slug
      ##
      def slugify_image(image)
        "#{IMAGE_SLUG_PREFIX}#{File.basename(image).sub(/\..{3,4}$/, '').gsub(/[^a-z0-9]/i, '-')}"
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

      ## Used to separate YAML headers in raw Markdown file.
      ## Called by #update_yaml. Should be private, but we're
      ## winging it here.
      ##
      ## @param      file  [String] The file path
      ##
      ## @return     [Array] header, body
      ##
      def split_header(file)
        raise "Invalid file: #{self}" unless File.exist? file

        parts = IO.read(self).split(/^---/)
        raise "Invalid YAML in #{self}" unless parts.count > 2

        header = parts[1]
        body = parts[2..-1].join('---')
        [header, body]
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
        return false if page.data['draft'] == true || page.data['published'] == false

        return false if page.data['archive'] == true || page.data['archived'] == true

        return false if Time.parse(page.data['date']) > Time.now

        true
      end

      ##
      ## Convert a relative image path to fully qualified
      ## path
      ##
      ## @param      base  The base directory for the page
      ## @param      img   The image path
      ##
      ## @return     [Hash] :src => src tag value, :file => absolute
      ##             path, :slug => slugified title, :alt => alt
      ##             description
      ##
      def expand_image(base, img)
        new_img = ".#{base}#{img[0].sub(%r{^https://github.com/oracle-devrel/devo.tutorials/raw/main/}, '')}"
        if File.exist?(File.expand_path(new_img))
          { src: img[0], file: new_img, slug: slugify_image(new_img), alt: img[1] }
        else
          alert("IMAGE FILE NOT FOUND: #{new_img}", type: :failure)
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
        images = html.scan(/<img.*?src="(.*?)".*?(?:alt="(.*?)")?/)

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
      ## Upload a single image. Called by #upload_images.
      ##
      ## @param      source  [String] image src value
      ## @param      image   [String] file path
      ## @param      slug    [String] image slug
      ## @param      alt     [String] alt text
      ##
      ## @return     [Hash] Image object containing :src, :id, :slug
      ##
      def upload_image(source, image, slug, alt)
        info("=== Uploading #{image}", type: :action)

        json = temp_json('imageFields', image_fields(alt).to_json)

        res = cec(%(create-digital-asset -f "../#{image}" -a ../#{json} -t ImageAsset -g en -l "#{slug}"))

        success = res.match(/created ImageAsset asset \((.*?)\)/)

        return error("Error uploading #{image}", type: :failure) if success.nil?

        image_hash(success, source)
      end

      ##
      ## Generate an image hash for use in other methods.
      ## Called by #upload_image
      ##
      ## @param      success  [String] The success message
      ##                      from the image upload
      ## @param      source   [String] The src value for the
      ##                      original image tag
      ##
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

        downloaded = status[:missing].map { |img| upload_image(img[:src], img[:file], img[:slug], img[:alt]) }
        downloaded.delete_if(&:nil?)

        status[:existing].concat(downloaded)
      end

      ##
      ## Create macros for each image and update html img
      ## tags
      ##
      ## @param      html    [String] the HTML to update
      ##
      ## @return     [String] new HTML
      ##
      def update_html_images(html)
        info("=== Updating #{@images.count} image tags", type: :action)
        @images.each do |img|
          next if img.nil?

          macro = "[!--$CEC_DIGITAL_ASSET--]#{img[:id]}[/!--$CEC_DIGITAL_ASSET--]"
          html.gsub!(/#{img[:src]}/, macro)
        end
        html
      end

      ##
      ## Convert an array of images to a string query
      ##
      ## @example    array_to_slug_query(["image_one",
      ## "image_two"]) => 'slug eq "image_one" or slug eq
      ## "image_two"'
      ##
      ## @param      array    [Array] The array of slugs
      ## @param      boolean  [String] The boolean (and|or)
      ##
      ## @return [String] query string
      ##
      def array_to_slug_query(array, boolean: 'or')
        array.map { |slug| %(slug eq "#{slug}") }.join(" #{boolean} ")
      end

      ##
      ## Download the site taxonomy and store it once in Util module
      ##
      ## @return     [Hash] taxanomy Hash
      ##
      def taxonomy
        Util.taxonomy ||= download_taxonomy
      end

      ##
      ## Download site taxonomy
      ##
      ## @return     [Hash] taxonomy hash
      ##
      def download_taxonomy
        taxonomy_file = File.expand_path('_temp/taxonomy.json')
        FileUtils.mkdir_p(File.dirname(taxonomy_file))
        cec("describe-taxonomy 'DevO-Developer Relations' -f #{taxonomy_file}", repo: false)
        data = JSON.parse(IO.read(taxonomy_file))
        tax_id = data['data']['id']
        url = "/content/published/api/v1.1/taxonomies/#{tax_id}/categories"
        query = ['limit=100', "channelToken=#{channel_token}"]
        cec("exeg '#{url}?#{query.join('&')}' -f #{taxonomy_file}", repo: false)
        json = JSON.parse(IO.read(taxonomy_file))
        clean_up_temp_files

        { id: tax_id, tags: json['items'] }
      end

      ##
      ## The repository ID
      ##
      def repository_id
        Util.repository_id ||= retrieve_repository_id
      end

      ##
      ## Download repository id
      ##
      ## @return     [String] The repository identifier.
      ##
      def retrieve_repository_id
        repo_file = File.expand_path('_temp/repo.json')
        FileUtils.mkdir_p(File.dirname(repo_file))
        cec("exeg '/sites/management/api/v1/sites/name:#{REPOSITORY}/repository' -f #{repo_file}", repo: false)
        data = JSON.parse(IO.read(repo_file))

        data['id']
      end

      ##
      ## The channel token
      ##
      ## @return     [String] channel token
      ##
      def channel_token
        Util.channel_token ||= retrieve_channel_token
      end

      ##
      ## Download the channel token from authorized server
      ##
      ## @return     [String] The channel token
      ##
      def retrieve_channel_token
        channel_file = File.expand_path('_temp/channel.json')
        FileUtils.mkdir_p(File.dirname(channel_file))
        cec("exeg '/sites/management/api/v1/sites/name:#{CHANNEL}/channel' -f #{channel_file}", repo: false)
        data = JSON.parse(IO.read(channel_file))

        data['channelTokens'][0]['token']
      end

      ##
      ## Translate a list of Jekyll tags to OCM ids
      ##
      ## @param      tags  The tags to translate
      ##
      def translate_tags(tags)
        Util.meta[:tags] = tags.map { |tag| cec_id_for_tag(tag) }.delete_if(&:nil?)
      end

      ##
      ## Get OCM tag name from local mapping in _data/cec_tags.yaml
      ##
      ## @param      tag   [String] The OCM tag to translate
      ##
      def cec_name_for_tag(tag)
        tags = YAML.safe_load(IO.read(File.expand_path('_data/cec_tags.yaml')))
        tags.key?(tag) ? tags[tag] : nil
      end

      ##
      ## Find the OCM ID for the tag name
      ##
      ## @param      tag   [String] The Jekyll tag name
      ##
      def cec_id_for_tag(tag)
        cec_name = cec_name_for_tag(tag)
        return nil if cec_name.nil? || cec_name.empty?

        id = nil
        taxonomy[:tags].each do |tax|
          if tax['name'] =~ /#{cec_name}/i
            id = tax['id']
            break
          end
        end

        id
      end

      ##
      ## Download multiple assets.
      ##
      ## Ugly bit of code, but I haven't had much luck
      ## refactoring it without just making it MORE complex.
      ## It won't hurt my feelings if you fix it.
      ##
      ## @return     [Hash] :existing (Array of images that exist on
      ##             server) and :missing (Array of images that need
      ##             uploading)
      ##
      ## @param      images  [Array] The images to download
      ##
      def download_existing(images)
        return { existing: [], missing: [] } if images.empty?

        existing = []

        query = array_to_slug_query(images.map { |i| i[:slug] })

        res = cec(%(download-content -q '#{query}'))
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
      def download_contents(slugs)
        return nil if slugs.empty?

        query = array_to_slug_query(slugs)

        res = cec(%(download-content -q '#{query}'))

        downloaded = res.match(/- total items to export: (?<total>\d+)/)
        return nil if downloaded.nil? || downloaded['total'].to_i.zero?

        dest = res.match(/- the assets are available at (?<dir>.*?)(?:\n|\Z)/)
        dest.nil? ? nil : dest['dir']
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
      ## @param      alt   [String] The image alt text
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
      ## @return     [Hash] values for JSON payload
      ##
      def empty_article_payload
        {
          'name' => Util.meta[:title],
          'type' => 'DEVO_GitHub-Technical-Content',
          'description' => '',
          'repositoryId' => repository_id,
          'slug' => Util.meta[:slug],
          'language' => 'en',
          'translatable' => true,
          'fields' => { 'html' => 'DEFINE' }
        }
      end

      ##
      ## Creates an empty article.
      ##
      def create_empty_article
        info('=== Creating empty article', type: :action)
        temp_json('uploadPayload', empty_article_payload.to_json)
        cec(%(execute-post "/content/management/api/v1.1/items" -b ../_temp/uploadPayload.json), repo: false)
        clean_up_temp_files
        sleep 5
      end

      ##
      ## Locate the JSON file for a downloaded article
      ##
      ## @param      tries   [Integer] number of times to
      ##                     retry on failure
      ##
      ## @return     [Array] base directory and article JSON path
      ##
      def article_data(images = [], tries = 4)
        existing = nil
        article = nil

        tries.times do |try|
          info("=== Downloading contents for #{Util.meta[:slug]}", type: :action)

          existing = download_contents([Util.meta[:slug]].concat(images.map { |img| img[:slug] }))

          if existing
            path = File.join(existing, 'contentexport', 'ContentItems', 'DEVO_GitHub-Technical-Content', '*.json')
            article = Dir.glob(path)[0]
          end

          break unless article.nil?

          alert("=== Failed to download #{Util.meta[:slug]} (try #{try}), trying again in #{RETRY_DELAY} seconds",
                type: :warning)
          sleep RETRY_DELAY
        end

        return info("#{Util.meta[:slug]} doesn't exist, ignoring", type: :result) if existing.nil?

        [existing, article]
      end

      def publish(query)
        cec(%(control-content publish -q '#{query}' -c #{CHANNEL}))
      end

      def publish_status(res, type: :image)
        if res =~ /- no item to publish/
          error("=== Failed to publish #{type == :image ? 'images' : 'article page'} for #{Util.meta[:slug]}",
                type: :failure) || false
        else
          info("=== Published #{type == :image ? 'images' : 'article page'} for #{Util.meta[:slug]}",
               type: :success) || true
        end
      end

      ##
      ## Publish an article to live site
      ##
      def publish_article
        if @images.count.positive?
          info("=== Publishing #{@images.count} images", type: :action)

          query = array_to_slug_query(@images.map { |i| i[:slug] })
          res = publish(query)
          publish_status(res, type: :image)
        end

        info("=== Publishing #{Util.meta[:slug]}", type: :action)

        res = publish(%(slug eq "#{Util.meta[:slug]}"))
        publish_status(res, type: :page)
      end

      ##
      ## Unpublish an article from the live site
      ##
      def unpublish_article
        info("=== Unpublishing #{Util.meta[:slug]}", type: :action)

        query = %(slug eq "#{Util.meta[:slug]}")
        cec(%(control-content unpublish -q '#{query}' -c #{CHANNEL}))

        info("=== Unpublished #{Util.meta[:slug]}", type: :success) || true
      end

      ##
      ## Fully archive an article and its images. This makes
      ## them invisible to the web interface as well.
      ##
      def archive_article
        info("=== #{Util.meta[:slug]} not published, archiving", type: :action)

        _, article = article_data([], 2)

        return if article.nil?

        data = JSON.parse(IO.read(article))

        query = generate_batch_query(data['id'], @images)
        json = temp_json('archivePayload', { 'q' => query }.to_json)

        cec(%(execute-post "/content/management/api/v1.1/bulkItemsOperations/archive" -b ../#{json}), repo: false)

        info("=== Archived #{Util.meta[:slug]} and images", type: :success)
        clean_up_temp_files
      end

      ##
      ## Generate a query string from article and image ids. Called by #archive_article
      ##
      ## @param      article_id  [String] The article identifier
      ##
      def generate_batch_query(article_id)
        image_ids = @images.map { |image| image[:id] }
        [article_id].concat(image_ids).map { |id| %(id eq "#{id}") }.join(' or ')
      end

      ##
      ## Test whether the local and server versions of an
      ## article differ. Called by #upload_article.
      ##
      ## @param      data  [Hash]  The article data
      ## @param      html  [String] The html
      ##
      ## @return     [Boolean] true if content differs
      ##
      def article_changed?(data, html)
        return true if data['fields']['html'] != html

        return true if data['display_chapters'] != Util.meta[:toc_enabled]

        return true if data['taxonomies'] != tags_to_struct

        false
      end

      def tags_to_struct
        return {} if Util.meta[:tags].nil? || Util.meta[:tags].empty?

        {
          'data' => [
            {
              'id' => taxonomy[:id],
              'categories' => Util.meta[:tags].map { |id| { 'id' => id } }
            }
          ]
        }
      end

      ##
      ## Upload a new article by generating a manifest,
      ## updating fields, and zipping/pushing to the server.
      ##
      ## @param      html     [String] The article html
      ##                      content
      ## @param      base     [String] The base directory of
      ##                      the assets to be zipped
      ## @param      article  [String] Path to the article
      ##                      manifest
      ##
      def upload_article(html, base, article)
        data = JSON.parse(IO.read(article))

        return info("=== No change in #{Util.meta[:slug]}", type: :success) unless article_changed?(data, html)

        data = update_field(data, 'html', html)
        data = update_field(data, 'display_chapters', Util.meta[:toc_enabled])
        data = update_field(data, 'author_slug', Util.meta[:author])
        data['taxonomies'] = tags_to_struct

        File.open(article, 'w') { |f| f.puts data.to_json }

        generate_assets(base, data['id'])
      end

      ##
      ## Called by #upload_article
      ##
      def update_field(data, key, value)
        data['fields'][key] = value
        data
      end

      ##
      ## Convert @images array to a single JSON field. Called by #upload_article
      ##
      ## @param      base        [String] The base path
      ## @param      article_id  [String] The article identifier
      ##
      def generate_assets(base, article_id)
        path = File.join(base, 'contentexport', 'metadata.json')
        data = JSON.parse(IO.read(path))

        assets = @images.map { |img| "ImageAsset:#{img[:id]}" }
        assets.push("DEVO_GitHub-Technical-Content:#{article_id}")

        update_manifest(data, assets, path)
        zip_and_publish(base)
      end

      ##
      ## Called by #generate_assets
      ##
      ## @param      data    The data
      ## @param      assets  The assets
      ## @param      path    The path
      ##
      def update_manifest(data, assets, path)
        data['groups'].to_i.times { |x| data.delete("group#{x}") }

        data['groups'] = 2
        data['group0'] = if assets.count > 1
                           %w[DEVO_GitHub-Technical-Content ImageAsset']
                         else
                           ['DEVO_GitHub-Technical-Content']
                         end
        data['group1'] = assets

        File.open(path, 'w') { |f| f.puts data.to_json }
      end

      ##
      ## Zip and upload the manifest. Called by #generate_assets
      ##
      ## @param      base  [String] The base path to zip
      ##
      def zip_and_publish(base)
        Dir.chdir(base)
        zip = TTY::Which.which('zip')
        `#{zip} -r payload.zip *`
        Dir.chdir(Util.pwd)
        res = cec(%(upload-content #{File.join(base, 'payload.zip')} -f -u -c #{CHANNEL}))

        if res =~ /ERROR: import failed/
          error("=== Failed to create #{Util.meta[:slug]}", type: :failure) || false
        else
          info("=== Successfully uploaded #{Util.meta[:slug]}", type: :success) || true
        end
      end

      ##
      ## Create an article on the server
      ##
      ## @param      html    [String] The html
      ##
      def create_article(html, published)
        create_empty_article if download_content(Util.meta[:slug]).nil?
        base, article = article_data(@images, 4)

        return error("Failed to retrieve article for #{Util.meta[:slug]}", type: :failure) if article.nil?

        res = upload_article(html, base, article)

        return false unless res

        published ? publish_article : unpublish_article

        res
      end

      ##
      ## Prepare, create, and publish a Jekyll page. Called by #process_page
      ##
      ## @param      page  [Page] The page to publish
      ##
      def render_page(page)
        translate_tags(page.data['tags'])

        @images = gather_images(page.dir, page.output)
        html = HtmlPress.press(update_html_images(page.output))

        info("=== Creating article #{Util.meta[:slug]} with #{@images.count} images", type: :action)
        create_article(html, published?(page))

        info("===== Finished #{Util.meta[:slug]}", type: :finish)
        Util.clock(:page, :finish)
        Util.print_bench(:page, border: true, title: Util.meta[:slug], level: :debug)
      end

      ##
      ## Figure out the author slug if available. Called by #process_page
      ##
      ## @param      page  [Page] The page
      ##
      def get_page_author(page)
        author = ''
        if page.data['author']
          author = if page.data['author'].is_a?(String)
                     page.data['author'].gsub(/ +/, '-').downcase
                   elsif page.data['author'].key?('name')
                     page.data['author']['name'].gsub(/ +/, '-').downcase
                   end
        end
        author
      end

      ##
      ## Set up meta based on page values for use by all methods
      ##
      ## @param      page  [Page] The page
      ##
      def process_page(page)
        Util.meta = {
          slug: slugify(page),
          title: page.data['title'],
          author: get_page_author(page),
          toc_enabled: page.data['toc'],
          tags: []
        }
        Util.clock(:page, :start)
        Util.timestamp('Starting page render')

        info("===== Rendering #{Util.meta[:slug]} (#{Util.meta[:title]})", type: :start)
        render_page(page)
      end
    end

    # Post-render Jekyll hook activates after each page is
    # rendered. Receives the page object and all its
    # methods, including rendered content and meta
    Jekyll::Hooks.register :pages, :post_render do |page|
      if ENV['CEC_DEPLOY'] =~ /(1|true)/
        raise 'This plugin requires the zip command to be in PATH' unless TTY::Which.exist?('zip')

        process_page(page) if page.data['parent']
      end
    end

    Jekyll::Hooks.register :site, :pre_render do
      Color.coloring = $stdout.isatty
      # tee = TeeIO.new $stdout, File.new("#{Time.now.strftime('%F_%T')}-CEC_LOG.txt", 'w')
      # $stdout = tee
      Util.clock(:total, :start)
      Util.timestamp("Deploy started")
      # Stores the current directory as Util.pwd for reference after chdir commands
      Util.pwd
    end

    Jekyll::Hooks.register :site, :post_write do
      Util.clock(:total, :finish)
      Util.print_bench(:total, border: true, level: :info, type: :finish)

      if Util.errors.count.positive?
        puts 'ERRORS:'
        puts Util.errors
        raise StandardError, 'Errors occurred', []
      end
    end
  end
end

=begin notes
# Current Steps

1. Trigger after rendering HTML and all Liquid tags
2. Scan for images, download them all
3. Check downloads to see if any images are missing, upload missing images
4. Download OCM article if it exists, as well as all images (again)
5. Update HTML image tags with OCM macros
6. If HTML is different than what we have locally, update the HTML field
7. Add tags as taxonomy categories
8. If new or updated, upload the article and all images back to server with changes
9. Publish or unpublish the article based on meta

Very inefficient, but works. Slowly.

Recommend running once to publish all articles, then moving
articles into a _draft or _published folder to avoid
re-rendering them when not needed. To modify or add an
article, move it or add it to the tutorials folder and run
a build. Once successfully published, move it into
the _draft folder. To unpublish an article, add `draft:
true` or `published: false` to the front matter.

# Jekyll

- [x] only initiate hook when running a build. Must run build with CEC_DEPLOY=true
- [x] test for page.data['parent'] to determine if tutorial
- [x] test for page.data['published'] == false or page.data['draft'] == true
- [x] test for page.data['slug'], if empty generate slug from page.basename (apply to original page as slug front matter for permanence?)
- [x] modify template to output only main content block, no header or footer
- [x] if page.data['author'] is a string, use it for author_slug, if hash, use slugified author.name
- [x] modify image plugin to output simpler image tag with easily scannable paths, easy to substitute with OCM macro (remove srcset and data-*)
- [x] scan for images, output list of local paths (remove raw github url if present)
- [x] remove MRM plugin
- [ ] handle inter-document links, e.g. a series index. URLs need to point to dev.o
- [x] collect errors without exiting, but display them at the end of the build and exit non-zero
- [x] hide tags in output (phase 2), apply tags as taxonomy to published post

# CEC Toolkit

- [x] method for generating manifests and zip files
- [x] test for existing pages/images using slugs
- [x] archive if not #published?
- [x] upload images and replace src with macro
- [x] upload html

# Questions/Blockers

- [x] possible to publish via toolkit? (implemented)
- [x] if I archive an article and then try to republish it, I can't because the slug is already in use (switched to using unpublish instead of archive for now)
- [x] enable OCM-generated TOC
- [x] Adjust sidebar to contain author meta inline with the article (at bottom)
- [?] how to deal with series? Each series has an index page and links to other articles in the series. These links will obviously break. Also, we used to only show the series index in the content list, with its articles only visible from that index page. I assume that's not possible on OCM
- [?] can I retrieve a page's live url using its slug? Is there a macro for inserting a link to another page? That would at least let me update the links between articles on the same site.

# Osvaldo

- [?] I need info on how to install CEC Toolkit and init in the directory `_cec` in the Jenkins job. Hoping there's an expert who can help me out with that part.

# Jenkins

- [?] how do you trigger a Jenkins job with a GitHub Action? Or can Jenkins watch the tutorials repo for updates itself?
- [?] can the Jenkins job notify me by email if an error occurs? (The script will raise an exception and jekyll should return a non-zero exit code if it does)
- [?] does Jenkins have Secrets I can use to populate my constants?
=end
