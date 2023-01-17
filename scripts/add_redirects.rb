#!/usr/bin/env ruby -W1

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

raise "CSV filename required as argument" unless ARGV.count == 1

csv = ARGV[0]
raise "Missing file #{csv}" unless File.exist?(csv)

CSV.open(csv) do |data|
  data.each do |line|
    file = line[0]
    warn "Updating file: #{file}"
    header, body = file.split_header
    yaml = YAML.load(header)
    yaml['redirect'] = line[2]
    File.open(file, 'w') do |f|
      f.puts [YAML.dump(yaml), body].join('---')
    end
  end
end

