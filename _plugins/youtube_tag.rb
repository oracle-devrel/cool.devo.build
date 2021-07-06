# Title: YouTube embed tag
# Author: Brett Terpstra
# Description: Output a figure tag with YouTube embed iframe
#
# Syntax {% youtube video_id [width height] ["Caption"] %}
#
# Example:
# {% youtube B4g4zTF5lDo 480 360 %}
# {% youtube http://youtu.be/2NI27q3xNyI %}

module Jekyll
  class YouTubeTag < Liquid::Tag
    @videoid = nil
    @width = ''
    @height = ''

    def initialize(tag_name, markup, tokens)
      if markup =~ %r{(?:(?:https?://)?(?:www.youtube.com/(?:embed/|watch\?v=)|youtu.be/)?(\S+)(?:\?rel=\d)?)(?:\s+(\d+)\s(\d+))?(?:\s+"(.*?)")?}i
        m = Regexp.last_match
        @videoid = m[1]
        @width = m[2] || '480'
        @height = m[3] || '360'
        @caption = m[4] ? "<figcaption>#{m[4]}</figcaption>" : ''
      end
      super
    end

    def render(context)
      context.environments.first['page']['youtube'] = @videoid
      if @videoid
        emu = "https://www.youtube.com/embed/#{@videoid}?autoplay=0"
        video = %(<iframe width="#{@width}" height="#{@height}" style="vertical-align:top;" src="#{emu}" frameborder="0" allowfullscreen></iframe>)

        %(<figure class="yt-video-container">#{video}#{@caption}</figure>)
      else
        'Error processing input, expected syntax: {% youtube video_id [width height] %}'
      end
    end
  end
end

Liquid::Template.register_tag('youtube', Jekyll::YouTubeTag)
