# Title: Slides Tag
# Author: Brett Terpstra
# Description: Split content up by headlines and generate slides for paginated walkthrough
#
# (This is a mess of spaghetti I puked out at 9pm on a Tuesday night with the intention of refactoring it before it got too far. We'll see how that goes.)
#
# Syntax:
# {% slides [header level] %}MARKDOWN CONTENT{% endslides %}
#
# Example:
# {% slides 2 %}
# Intro content
#
# ## Slide 1
#
# Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
# ## Slide 2
#
# Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
# {% endslides %}

# Notes:
#
# Assigns true to page.slides
# Assigns an HTML block of navigation code to page.slides_nav
#
# Both of these can be used in templates, e.g. {% if page.slides %}{{ page.slides_nav }}{% endif %}
#
# Requires a bit of JavaScript, also currently messy. And jQuery. But it got the job done for now.
#
# ```jquery
# cool.slides = (function() {
#   function goToSlide(x) {
#     $('.slide.active').fadeOut(300, function(e) {
#       $('.active').removeClass('active');
#       $('*[data-target-slide=' + x + ']').addClass('active');
#       $('#slide-' + x).fadeIn(300).addClass('active');
#       window.scrollTo(0, 0);
#     });
#   }

#   return {
#       goToSlide: goToSlide
#   };
# }());
# ```


module Jekyll
  class SlidesBlock < Liquid::Block
    @level = nil

    def initialize(tag_name, markup, tokens)
      if markup.strip =~ /^\d$/
        @level = markup.strip.to_i
      else
        @level = 2
      end
      super
    end

    def render(context)
      context.environments.first['page']['slides'] = true
      input = super
      output = %(<div class="slides" id="slideshow" markdown=1>\n\n)

      sect_rx = /(?mi)^\#{#{@level}}(?=[^#])/
      sects = input.split(sect_rx).delete_if {|s| s.strip == ''}

      intro = sects.slice!(0)
      toc = [%(<li class="active" data-target-slide="0"><a href="javascript:cool.slides.goToSlide(0)">Intro</a></li>)]
      # nav = [%(<a href="#slide-0">0</a>)]
      output += %(\n\n<div class="slide active" id="slide-0" markdown=1>\n\n)
      output += %(<h2 class="slide__title"><span class="slide__num">1</span> Introduction</h2>\n\n)
      output += intro
      output += %(\n\n<div class="slide__nav"><a href="javascript:cool.slides.goToSlide(1)" class="slides__btn--begin">Begin &raquo;</a></div>)
      output += "\n\n</div>\n\n"

      sects.each_with_index do |sect, i|
        lines = sect.split(/\n/)
        headline = lines.slice!(0).strip
        output += %(\n\n<div class="slide" id="slide-#{i+1}" markdown=1>\n\n)
        output += %(<h2 class="slide__title"><span class="slide__num">#{i+2}</span> #{headline.strip}</h2>\n\n)
        output += lines.join("\n")
        output += %(\n\n<div class="slide__nav"><a href="javascript:cool.slides.goToSlide(#{i})">&laquo; Back</a>)
        if i < sects.length - 1
          output += %( <a href="javascript:cool.slides.goToSlide(#{i+2})">Continue &raquo;</a></div>)
        else
          output += "</div>"
        end
        output += %(\n\n</div>\n\n)
        toc << %(<li data-target-slide="#{i+1}"><a href="javascript:cool.slides.goToSlide(#{i+1})">#{headline.strip}</a></li>)
        # nav << %(<a href="javascript:cool.slides.goToSlide(#{i+1})" title="Jump to #{headline.strip}">#{i+1}</a>)
      end

      output += %(</div>\n\n)

      table_of_contents = %(<nav class="slides-nav"><ul>) + toc.join("\n") + "</ul></nav>"

      context.environments.first['page']['slides_nav'] = table_of_contents

      # result = output

      # result += %(<div class="slides-dots">)

      # nav.each {|slide| result += slide }

      output
    end

    Liquid::Template.register_tag('slides', self)
  end
end
