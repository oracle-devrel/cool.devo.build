#!/usr/bin/env ruby
# Update modified dates of changed Markdown files

class ::String
  def file_has_yaml?
    raise "Invalid file: #{self}" unless File.exist? self

    parts = IO.read(self).split(/^---/)
    return parts.count > 2
  end

  def get_yaml
    raise "Invalid file: #{self}" unless File.exist? self

    parts = IO.read(self).split(/^---/)
    raise "Invalid YAML in #{self}" unless parts.count > 2

    header = parts[1]
    body = parts[2..-1].join('---')
    [header, body]
  end
end

staged = `git diff-index --name-status --cached HEAD`.strip.split(/\n/).map {|f| f.sub(/^(A|M)\s*/, '')}
partial = `git status --porcelain --untracked-files=no`.strip.split(/\n/).map {|f| f.sub(/^(A|M)\s*/, '')}
changed = staged.concat(partial).sort.uniq
changed.select! {|f| f =~ /(md|markdown)$/ && f.file_has_yaml? }

modified = Time.now.strftime('%Y-%m-%d %H:%M:%S %z')
puts "Modified: #{modified}"

changed.each do |file|
  warn "Updating modified date: #{file}"
  header, body = file.get_yaml

  header.sub!(/^modified: .*?\n/, '')
  header += "modified: #{modified}"

  File.open(file, 'w+') do |f|
    f.puts '---'
    f.puts header.strip
    f.puts '---'
    f.puts body.strip
  end
end
