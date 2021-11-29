#!/usr/bin/env ruby

require 'csv'
require 'yaml'

class ::String
  def split_header
    raise "Invalid file: #{self}" unless File.exist? self

    parts = IO.read(self).split(/^---/)
    raise "Invalid YAML in #{self}" unless parts.count > 2

    header = parts[1]
    body = parts[2..-1].join('---')
    [header, body]
  end
end

CSV.open('mrm_codes.csv') do |data|
  data.each do |line|
    filename = line[0].sub(%r{^.*?/tutorials/(.*?)(\.html)?$}, '\1')
    file = File.expand_path("tutorials/#{filename}.md")
    puts "Updating file: #{file}"
    header, body = file.split_header
    yaml = YAML.load(header)
    yaml['mrm'] = line[1]
    File.open(file, 'w') do |f|
      f.puts [YAML.dump(yaml), body].join('---')
    end
  end
end

