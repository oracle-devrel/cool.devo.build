#!/usr/bin/env ruby

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

raise "Invalid number of arguments. Usage: rename_key.rb ORIG_KEY NEW_KEY" unless ARGV.count == 2

orig_key = ARGV[0]
new_key = ARGV[1]

Dir.glob(['*.md', '**/*.md']).each do |file|
  begin
    header, body = file.split_header
    yaml = YAML.load(header)
    if yaml.key?(orig_key)
      yaml[new_key] = yaml.delete(orig_key)
      puts "Updating file: #{file}"
      File.open(file, 'w') do |f|
        f.puts [YAML.dump(yaml), body].join('---')
      end
    end
  rescue
    next
  end
end

