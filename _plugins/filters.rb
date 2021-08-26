class String
  def fix_encoding
    converter = Iconv.new 'UTF-8//IGNORE', 'UTF-8'
    converter.iconv(self)
  end
end

module BTLiquidFilters

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

  def relative_to(input, page)
    return input if input =~ /^(\/|http)/

    dir = File.dirname(page)
    baseurl = Jekyll.sites.first.baseurl
    File.join(baseurl, dir, input)
  end

  # remove all HTML tags and smart quotes
  def strip_tags(html,decode=true)
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

  Liquid::Template.register_filter self
end
