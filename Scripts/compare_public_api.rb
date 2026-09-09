#!/usr/bin/env ruby

require "json"
require "set"

old_path, new_path, *options = ARGV
unless old_path && new_path
  warn "Usage: compare_public_api.rb OLD.json NEW.json [--allow-removals]"
  exit 2
end

def entries(path)
  JSON.parse(File.read(path)).fetch("declarations", []).map do |entry|
    declaration = entry.fetch("declaration").to_s.gsub(/\s+/, " ")
    kind = entry["kind"].to_s
    signature = if kind == "class" && declaration.match?(/\bclass\s+func\b/)
                  declaration[/\bclass\s+func\s+([A-Za-z_][A-Za-z0-9_]*)/, 1] || declaration
                elsif %w[var let].include?(kind)
                  declaration[/\b(?:var|let)\s+([A-Za-z_][A-Za-z0-9_]*)/, 1] || declaration
                elsif %w[class struct enum protocol actor].include?(kind)
                  declaration[/\b#{kind}\s+([A-Za-z_][A-Za-z0-9_]*)/, 1] || declaration
                else
                  declaration.sub(/[\{;].*$/, "").strip
                end
    [entry["path"], entry["access"], entry["kind"], signature].join("|")
  end.to_set
end

old_entries = entries(old_path)
new_entries = entries(new_path)
removed = (old_entries - new_entries).sort
added = (new_entries - old_entries).sort

puts "Public API comparison"
puts "  old=#{old_entries.length}"
puts "  new=#{new_entries.length}"
puts "  added=#{added.length}"
puts "  removed=#{removed.length}"

unless added.empty?
  puts "Added declarations:"
  added.each { |entry| puts "+ #{entry}" }
end

unless removed.empty?
  warn "Removed declarations:"
  removed.each { |entry| warn "- #{entry}" }
end

exit 1 if !removed.empty? && !options.include?("--allow-removals")
