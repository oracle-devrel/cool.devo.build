# Title: Simple Image tag for Jekyll
# Authors: Brett Terpstra
# Description: Easily output images with optional class names, width, height, title and alt attributes
#
# Additions: REVAMPED to use loading="lazy"
#            insert @2x data attribute - this uses an htaccess rule that serves the
#              1x if no @2x version exists.
#
#              if tag is {% imgd %}, set as default image for social sharing
#
# Syntax {% img [class name(s)] [http[s]:/]/path/to/image [width height] [title text | "title text" ["alt text"]] %}
#
# Examples:
# {% img /images/ninja.png Ninja Attack! %}
# {% img left half http://site.com/images/ninja.png Ninja Attack! %}
# {% img left half http://site.com/images/ninja.png 150 150 "Ninja Attack!" "Ninja in attack posture" %}
#
# Output:
# <img src="/images/ninja.png">
# <img class="left half" src="http://site.com/images/ninja.png" title="Ninja Attack!" alt="Ninja Attack!">
# <img class="left half" src="http://site.com/images/ninja.png" width="150" height="150" title="Ninja Attack!" alt="Ninja in attack posture">
#
module Jekyll

  class ImageTag < Liquid::Tag
    @img = {}
    @is_default = false

    def initialize(tag_name, markup, tokens)
      if markup =~ /^\s*(?<class>(?:\S+ )*)(?<path>(?:https?:\/\/|\/|\S+\/)\S+)(?:\s+(?<width>\d+))?(?:\s+(?<height>\d+))?(?:\s+(?<title>.*))?/i
        m = Regexp.last_match
        unless m['path'].nil?
          imgclass = m['class'] || nil
          image = m['path']
          width = m['width'] || nil
          height = m['height'] || nil
          title = m['title'] || nil
          @img = {}
          @img['class'] = imgclass ? "#{imgclass.strip}" : ""
          @img['loading'] = "lazy"

          if width && height
            @img['width'] = width
            @img['height'] = height
          end

          @img['src'] = image
          @img['data-original'] = image

          if image =~ /@2x\./
            image2 = image
          else
            image2 = image.sub(/\.(png|jpe?g|gif)$/, '@2x.\1')
          end

          @img['data-at2x'] = image2

          if title && title !~ /^[\s"]*$/
            if /(?mi)"(?<xtitle>.*?)?"\s+"(?<alt>.*?)?"/ =~ title
              m = Regexp.last_match
              @img['title']  = m['xtitle']
              @img['alt']    = m['alt']
            else
              @img['alt']    = title.gsub(/(^["\s]*|["\s]*$)/, '')
            end
          end
        end

        if tag_name.strip == 'imgd'
          @is_default = true
        end
      end
      super
    end

    def render(context)
      unless @img.empty?
        dir = File.dirname(context.environments.first['page']['path'])
        warn "@2x: #{File.join(dir, @img['data-at2x'])}"
        srcset = %(<source srcset="#{@img['data-original']} 1x)
        if File.exist?(File.join(dir, @img['data-at2x']))
          srcset += %(, #{@img['data-at2x']} 2x)
        end
        srcset += %(" />)

        if @img.key?('title')
          figclass = @img['class'].sub(/lazy\s*/,'')
          @img['class'] = nil
          %Q{<figure class="#{figclass}">
              <picture>
                  #{srcset}
                  <img #{@img.collect {|k,v| "#{k}=\"#{v}\"" if v}.join(" ")} />
              </picture>
              <figcaption>#{@img['title']}</figcaption>
            </figure>}
        else
          @img['title'] = @img['alt']
          figclass = @img.delete('class')

          %Q{<picture class="#{figclass}">
                #{srcset}
                <img #{@img.collect {|k,v| "#{k}=\"#{v}\"" if v}.join(" ")} />
            </picture>}
        end
      else
        "Error processing input, expected syntax: {% img [class name(s)] [http[s]:/]/path/to/image [width [height]] [title text | \"title text\" [\"alt text\"]] %}"
      end
    end
  end
end

Liquid::Template.register_tag('imgx', Jekyll::ImageTag)
Liquid::Template.register_tag('img', Jekyll::ImageTag)
Liquid::Template.register_tag('imgd', Jekyll::ImageTag)
