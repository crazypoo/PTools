#!/usr/bin/env ruby

require "json"
require "set"

old_path, new_path, *options = ARGV
unless old_path && new_path
  warn "Usage: compare_public_api.rb OLD.json NEW.json [--allow-removals]"
  exit 2
end

# English: Allow only removals explicitly reviewed for a release migration.
# Español: Permite solo las eliminaciones revisadas explícitamente para una migración de release.
# 中文：只允许发布迁移中明确审阅并登记的删除项。
allowlist_path = options.filter_map do |option|
  option.delete_prefix("--allow-removals-file=") if option.start_with?("--allow-removals-file=")
end.first

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
    # English: A public symbol keeps its API identity when its implementation moves to another source file.
    # Español: Un símbolo público conserva su identidad de API aunque su implementación cambie de archivo fuente.
    # 中文：公开符号移动到其他源码文件时，API 身份仍由访问级别、类型和签名决定。
    [entry["access"], entry["kind"], signature].join("|")
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

if allowlist_path
  allowlisted = File.readlines(allowlist_path, chomp: true)
    .reject { |line| line.match?(/^\s*(#|$)/) }
    .to_set
  removed_set = removed.to_set
  unexpected = removed_set - allowlisted
  stale = allowlisted - removed_set
  unless unexpected.empty? && stale.empty?
    warn "Allowlisted API removals do not match the current diff"
    warn "Unexpected removals: #{unexpected.sort.inspect}" unless unexpected.empty?
    warn "Stale allowlist entries: #{stale.sort.inspect}" unless stale.empty?
    exit 1
  end
  puts "Allowlisted removals: #{removed.length}"
end

exit 1 if !removed.empty? && !options.include?("--allow-removals") && !allowlist_path
