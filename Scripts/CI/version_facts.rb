#!/usr/bin/env ruby

# English: Keep release-tag discovery in one implementation for every quality gate.
# Español: Mantiene el descubrimiento de etiquetas de release en una sola implementación para todas las puertas de calidad.
# 中文：将正式发布标签发现集中到一个实现，供所有质量门禁复用。

require "json"
require "open3"
require "rubygems"

repo_root = File.expand_path("../..", __dir__)
version_path = File.join(repo_root, "VERSION")
current_version = Gem::Version.new(File.read(version_path).strip)

semantic_tags = IO.popen(["git", "-C", repo_root, "tag", "--list"], &:read)
  .lines(chomp: true)
  .select { |tag| tag.match?(%r{\A\d+\.\d+\.\d+\z}) }
  .select { |tag| Gem::Version.new(tag) <= current_version }

ignored_tags = []
formal_tags = semantic_tags.select do |tag|
  content, status = Open3.capture2e("git", "-C", repo_root, "show", "#{tag}:VERSION")
  if status.success? && content.strip == tag
    true
  else
    ignored_tags << tag
    false
  end
rescue SystemCallError
  ignored_tags << tag
  false
end

# English: Keep CI output useful by reporting only malformed tags in the current product line.
# Español: Mantiene útil la salida de CI informando solo de etiquetas defectuosas de la línea actual.
# 中文：只报告当前产品线的异常标签，避免第三方历史标签淹没 CI 日志。
ignored_tags.select { |tag| tag == "5.56.0" || tag.start_with?("5.56.") }.each do |tag|
  warn "[QUALITY][VERSION][TAG_IGNORED] #{tag}: tag VERSION does not match the tag name"
end

command = ARGV.fetch(0, "latest-formal-tag")
case command
when "current-version"
  puts current_version
when "latest-formal-tag"
  puts(formal_tags.max_by { |tag| Gem::Version.new(tag) } || "")
when "latest-api-baseline-tag"
  available = formal_tags.select do |tag|
    File.file?(File.join(repo_root, "api-baseline", tag, "public_api.json"))
  end
  puts(available.max_by { |tag| Gem::Version.new(tag) } || "")
when "json"
  latest_api_baseline = formal_tags.select do |tag|
    File.file?(File.join(repo_root, "api-baseline", tag, "public_api.json"))
  end.max_by { |tag| Gem::Version.new(tag) }
  puts JSON.pretty_generate(
    "currentVersion" => current_version.to_s,
    "semanticTags" => semantic_tags,
    "formalTags" => formal_tags,
    "latestFormalTag" => formal_tags.max_by { |tag| Gem::Version.new(tag) },
    "latestAPIBaselineTag" => latest_api_baseline
  )
else
  warn "Usage: version_facts.rb current-version|latest-formal-tag|latest-api-baseline-tag|json"
  exit 64
end
