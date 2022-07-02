#!/usr/bin/env ruby
# frozen_string_literal: true

# Converts Markdown syntax to Liquid tag
# If image is a PNG converts to JPEG
# Detect size and include in tag
require 'fileutils'

content = IO.read(ARGV[0])

content.gsub!(/!\[(.*?)\]\((.*?)\)/) do
  m = Regexp.last_match
  alt = m[1]
  src = m[2]
  if src =~ /\.png$/
    target = src.sub(/\.png$/, '.jpg')
    `/usr/local/bin/convert "#{src}" -background white -flatten  -alpha off "#{target}" &> /dev/null`
    if File.exist?(target)
      FileUtils.rm(src)
      src = target
    end
  end

  alt = File.basename(src) if alt.nil? || alt.empty?

  width = `sips -g pixelWidth "#{src}"|tail -n 1`.gsub(/pixelWidth: /,'').strip
  height = `sips -g pixelHeight "#{src}"|tail -n 1`.gsub(/pixelHeight: /,'').strip

  %({% imgx aligncenter #{src} #{width} #{height} "#{alt}" %})
end

File.open(ARGV[0], 'w') do |f|
  f.puts content
end
