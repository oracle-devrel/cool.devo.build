require 'time'

class String
  def fix_encoding
    converter = Iconv.new 'UTF-8//IGNORE', 'UTF-8'
    converter.iconv(self)
  end

  def append_query(string)
    if self =~ /\?/
      "#{self}&#{string.sub(/^[?&]/, '')}"
    else
      "#{self}?#{string.sub(/^[?&]/, '')}"
    end
  end
end

module BTLiquidFilters
  def link_mrm(input, mrm)
    input.gsub(%r{(?<=")https?://.*?oracle(cloud)?\.com/.*?(?=")}) do
      url = Regexp.last_match(0)
      url =~ /:::::/ ? url : url.append_query("source=:ex:tb:::::#{mrm}:WW_FY22_DevRel_DotBuild&SC=:ex:tb:::::#{mrm}:WW_FY22_DevRel_DotBuild&pcode=#{mrm}")
    end
  end

  def fixer(input)
    input.fix_encoding || input
  end

  def tag_classes(input)
    if input
      input.map {|t| "tag-#{t}" }.join(" ")
    else
      ''
    end
  end

  def dirname(input)
    File.dirname(input)
  end

  def absolute_url(input)
    site_url = @context.registers[:site].config['url']
    base_url = @context.registers[:site].config['baseurl']

    return File.join(site_url, base_url) if input.nil?

    File.join(site_url, base_url, input)
  end

  def relative_to(input, page)
    return input if input =~ %r{^(/|http)}

    input ||= ''

    dir = File.dirname(page)
    base_url = @context.registers[:site].config['baseurl']
    File.join(base_url, dir, input)
  end

  def feed_markdownify(input, source)
    return '' if input.nil?

    site = @context.registers[:site]
    site_url = site.config['url']
    site_url = File.join(site_url, site.config['baseurl'])
    site_url = File.join(site_url, File.dirname(source))
    puts site_url
    converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
    input.gsub!(/!\[(.*?)\]\(((?!http).*?\))/) do
      m = Regexp.last_match
      path = File.join
      "![#{m[1]}](#{File.join(site_url, m[2])})"
    end
    input.gsub!(/\{% *img \s*(?<class>(?:\S+ )*)(?<path>(?:https?:\/\/|\/|\S+\/)\S+)(?:\s+(?<width>\d+))?(?:\s+(?<height>\d+))?(?:\s+(?<title>.*))?%\}/i) do
      m = Regexp.last_match
      path = File.join(site_url, m['path'])
      "![#{m['title']}](#{path})"
    end
    input.gsub!(/\{% *(end)?slides *%\}/, '')
    converter.convert(input)
  end

  # remove all HTML tags and smart quotes
  def strip_tags(html, decode=true)
    begin
      out = CGI.unescapeHTML(html.
        gsub(/<(script|style|pre|code|figure).*?>.*?<\/\1>/im, '').
        gsub(/<!--.*?-->/m, '').
        gsub(/<(img|hr|br).*?>/i, " ").
        gsub(/<(dd|a|h\d|p|small|b|i|blockquote|li)( [^>]*?)?>(.*?)<\/\1>/i, " \\3 ").
        gsub(/<\/?(dt|a|ul|ol)( [^>]+)?>/i, " ").
        gsub(/<[^>]+?>/, '').
        gsub(/\[\d+\]/, '').
        gsub(/&#8217;/,"'").gsub(/&.*?;/,' ').gsub(/;/,' ').
        gsub(/\u2028/,'')
      ).lstrip
      if decode
        out.force_encoding("ASCII-8BIT").gsub("\xE2\x80\x98","'").gsub("\xE2\x80\x99","'").gsub("\xCA\xBC","'").gsub("\xE2\x80\x9C",'"').gsub("\xE2\x80\x9D",'"').gsub("\xCB\xAE",'"').squeeze(" ")
      else
        out.squeeze(" ")
      end
    rescue
      CGI.unescapeHTML(html)
    end
  end

  def year(date)
    date = Time.parse(date) if date.class == String
    date.strftime('%Y')
  end

  def dotdate(date)
    date = Time.parse(date) if date.class == String
    date.strftime('%Y.%m.%d')
  end

  def utc(date)
    date = Time.parse(date) if date.class == String
    date.strftime('%FT%T%:z')
  end

  def remove_trailing_slash(input)
    input.sub(%r{\/$}, '')
  end

  def ensure_trailing_slash(input)
    input.sub(%r{\/?$}, '/')
  end

  def remove_leading_slash(input)
    input.sub(%r{^\/}, '')
  end

  def ensure_leading_slash(input)
    input.sub(%r{^\/?}, '/')
  end

  # https://github.com/bryanveloso/jekyll-widont/blob/master/_plugins/widont.rb
  def widont(input)
    text = input.dup
    text.sub!(/(January|February|March|April|May|June|July|August|September|October|November|December)\s+([\d,]+(?:nd|th)?)(?:\s+(\d+))?/i) do |m|
      m.gsub(/ +/,'&nbsp;')
    end
    text.strip.gsub(/([^\s])\s+([^\s]{1,8})\s*$/, '\1&nbsp;\2')
  end

  def strip_markdown(input)
    # strip all Markdown and Liquid tags
    output = input.dup
    begin
      output.gsub!(/\{%.*?%\}/,'')
      output.gsub!(/\{[:\.].*?\}/,'')
      output.gsub!(/\[\^.+?\](\: .*?$)?/,'')
      output.gsub!(/\s{0,2}\[.*?\]: .*?$/,'')
      output.gsub!(/\!\[.*?\][\[\(].*?[\]\)]/,"")
      output.gsub!(/\[(.*?)\][\[\(].*?[\]\)]/,"\\1")
      output.gsub!(/^\s{1,2}\[(.*?)\]: (\S+)( ".*?")?\s*$/,'')
      output.gsub!(/^\#{1,6}\s*/,'')
      output.gsub!(/(\*{1,2})(\S.*?\S)\1/,"\\2")
      output.gsub!(/\{[%{](.*?)[%}]\}/,"\\1")
      output.gsub!(/(`{3,})(.*?)\1/m,"\\2")
      output.gsub!(/^-{3,}\s*$/,"")
      output.gsub!(/`(.+)`/,"\\1")
      output.gsub!(/(?i-m)(_|\*)+(\S.*?\S)\1+/) {|match|
        $2.gsub(/(?i-m)(_|\*)+(\S.*?\S)\1+/,"\\2")
      }
      output.gsub(/\n{2,}/,"\n\n")
    rescue
      return input
    else
      output
    end
  end

  def trunc(input, length)
    return "" if input.nil?
    if input.length > length && input[0..(length-1)] =~ /(.+)\b.+$/im
      $1
    else
      input
    end
  end

  def keyword_string(keywords)
    keywords.join(" ").strip
  end

  def trailing_comma(kstring)
    kstring + "," unless kstring.nil? || kstring.length == 0
  end

  def og_tags(tags)
    tags.map {|tag|
      %Q{<meta property="article:tag" content="#{tag}">}
    }.join("\n")
  end

  def in_series(input)
    return !input['parent'].nil? && input['url'] !~ /\.(js|css|xml|txt|html)$/
  end

  def is_series(input)
    return !input['series'].nil? && input['url'] !~ /\.(js|css|xml|txt|html)$/
  end

  def placeholder_class(input)
    c = case input[0].downcase
        when /[a-e]/
          'red'
        when /[f-l]/
          'green'
        when /[l-r]/
          'blue'
        when /[r-w]/
          'orange'
        when /[x-z]/
          'yellow'
        end
    "ph-#{c}"
  end

  def first_letter(input)
    input[0].upcase
  end

  def split_slides(input, level = 2)
    if level =~ /^\d+$/
      level = level.to_i
    else
      level = 2
    end

    output = %(<div class="slides" markdown=1>\n\n)

    sect_rx = /(?mi)^<h{#{level}}.*?>/
    sects = input.split(sect_rx).delete_if {|s| s.strip == ''}

    intro = sects.slice!(0)
    toc = [%(<a href="#slide-0">Intro</a>)]
    nav = [%(<a href="#slide-0">0</a>)]
    output += %(\n\n<div class="slide intro" id="slide-0" markdown=1>\n\n)
    output += intro
    output += "\n\n</div>\n\n"

    sects.each_with_index do |sect, i|
      lines = sect.split(/\n/)
      headline = lines.slice!(0).sub(/<\/h#{level}>$/, '').strip
      output += %(\n\n<div class="slide" id="slide-#{i+1}" markdown=1>\n\n)
      output += %(<h2 class="slide-title">#{headline.strip}</h2>\n\n)
      output += lines.join("\n")
      output += %(\n\n</div>\n\n)
      toc << %(<a href="#slide-#{i+1}">#{headline.strip}</a>)
      nav << %(<a href="#slide-#{i+1}">#{i+1}</a>)
    end

    output += %(</div>\n\n)

    result = %(<nav class="slides-nav"><ul>)

    toc.each {|slide| result += "<li>#{slide}</li>" }

    result += "</ul></nav>"

    result += output

    result += %(<div class="slides-dots">)

    nav.each {|slide| result += slide }

    result
  end

  def strip_markdown(input)
    # strip all Markdown and Liquid tags
    output = input.dup
    begin
      output.gsub!(/\{%.*?%\}/,'')
      output.gsub!(/\{[:\.].*?\}/,'')
      output.gsub!(/\[\^.+?\](\: .*?$)?/,'')
      output.gsub!(/\s{0,2}\[.*?\]: .*?$/,'')
      output.gsub!(/\!\[.*?\][\[\(].*?[\]\)]/,"")
      output.gsub!(/\[(.*?)\][\[\(].*?[\]\)]/,"\\1")
      output.gsub!(/^\s{1,2}\[(.*?)\]: (\S+)( ".*?")?\s*$/,'')
      output.gsub!(/^\#{1,6}\s*/,'')
      output.gsub!(/(\*{1,2})(\S.*?\S)\1/,'\2')
      output.gsub!(/\{[%{](.*?)[%}]\}/,'')
      output.gsub!(/\{#(.*?)\}/,'')
      output.gsub!(/(`{3,})(.*?)\1/m,'\2')
      output.gsub!(/^-{3,}\s*$/,'')
      output.gsub!(/`/,'')
      output.gsub!(/(?i-m)(_|\*)+(\S.*?\S)\1+/) {|match|
        $2.gsub(/(?i-m)(_|\*)+(\S.*?\S)\1+/,'\2')
      }
      output.gsub(/\n{2,}/,"\n\n")
    rescue
      return input
    else
      output
    end
  end

  Liquid::Template.register_filter self
end
