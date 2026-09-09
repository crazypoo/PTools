#!/usr/bin/env ruby

# English: Generate a deterministic CocoaPods subspec and dependency graph.
# Español: Genera un grafo determinista de subspecs y dependencias de CocoaPods.
# 中文：生成可重复的 CocoaPods subspec 与依赖关系图。

require "cocoapods"
require "fileutils"
require "json"

REPO_ROOT = File.expand_path("..", __dir__)
REPORT_DIR = File.join(REPO_ROOT, "report")
JSON_PATH = File.join(REPORT_DIR, "cocoapods_subspec_graph.json")
MARKDOWN_PATH = File.join(REPORT_DIR, "cocoapods_subspec_graph.md")

def fail_with(message)
  warn "FAIL: #{message}"
  exit 1
end

begin
  specification = Pod::Specification.from_file(File.join(REPO_ROOT, "PooTools.podspec"))
rescue StandardError => error
  fail_with("unable to parse PooTools.podspec: #{error.message}")
end

def all_subspecs(specification)
  specification.subspecs.sort_by(&:name).flat_map do |subspec|
    [subspec] + all_subspecs(subspec)
  end
end

def array_value(value)
  Array(value).map { |item| item.to_s }.sort
end

def source_directories(source_files)
  patterns = Array(source_files).flat_map { |value| value.to_s.split }
  patterns.filter_map do |pattern|
    match = pattern.match(%r{PooToolsSource/([^/]+)/})
    match && match[1]
  end.uniq.sort
end

subspec_records = all_subspecs(specification).map do |subspec|
  attributes = subspec.attributes_hash
  dependencies = subspec.dependencies.map(&:name).sort
  local_dependencies = dependencies.select { |name| name == "PooTools" || name.start_with?("PooTools/") }
  {
    "name" => subspec.name,
    "short_name" => subspec.name.delete_prefix("#{specification.name}/"),
    "local_dependencies" => local_dependencies,
    "third_party_dependencies" => (dependencies - local_dependencies),
    "source_files" => array_value(attributes["source_files"]),
    "source_directories" => source_directories(attributes["source_files"]),
    "resource_bundles" => attributes["resource_bundles"] || {},
    "resources" => array_value(attributes["resources"]),
    "frameworks" => array_value(attributes["frameworks"]),
    "pod_target_xcconfig" => attributes["pod_target_xcconfig"] || {}
  }
end

graph = {
  "schema_version" => 1,
  "generator" => "Scripts/report_cocoapods_subspec_graph.rb",
  "name" => specification.name,
  "version" => specification.version.to_s,
  "platforms" => specification.attributes_hash["platforms"] || {},
  "swift_versions" => array_value(specification.swift_versions),
  "default_subspec" => Array(specification.attributes_hash["default_subspecs"]).first,
  "subspec_count" => subspec_records.length,
  "subspecs" => subspec_records
}

FileUtils.mkdir_p(REPORT_DIR)
File.write(JSON_PATH, JSON.pretty_generate(graph) + "\n")

markdown = []
markdown << "# CocoaPods Subspec Graph"
markdown << ""
markdown << "- Schema: `#{graph["schema_version"]}`"
markdown << "- Podspec: `#{graph["name"]}` `#{graph["version"]}`"
markdown << "- Default subspec: `#{graph["default_subspec"]}`"
markdown << "- iOS: `#{graph["platforms"]["ios"]}`"
markdown << "- Swift: `#{graph["swift_versions"].join(", ")}`"
markdown << "- Subspec count: `#{graph["subspec_count"]}`"
markdown << ""
markdown << "## Subspecs"
markdown << ""
markdown << "| Subspec | Local dependencies | Third-party dependencies | Source directories | Frameworks | Resources |"
markdown << "| --- | --- | --- | --- | --- | --- |"
subspec_records.each do |subspec|
  local = subspec["local_dependencies"].map { |name| "`#{name}`" }.join(", ")
  third_party = subspec["third_party_dependencies"].map { |name| "`#{name}`" }.join(", ")
  sources = subspec["source_directories"].map { |name| "`#{name}`" }.join(", ")
  frameworks = subspec["frameworks"].join(", ")
  resources = (subspec["resources"] + subspec["resource_bundles"].keys).uniq.join(", ")
  markdown << "| `#{subspec["short_name"]}` | #{local.empty? ? "—" : local} | #{third_party.empty? ? "—" : third_party} | #{sources.empty? ? "—" : sources} | #{frameworks.empty? ? "—" : frameworks} | #{resources.empty? ? "—" : resources} |"
end
markdown << ""
markdown << "## Notes"
markdown << ""
markdown << "- This report parses the checked-in podspec and does not resolve or change external Pods."
markdown << "- `PooTools/Core` is represented by its complete source-directory list because it is the default subspec boundary."
markdown << "- Legacy spelling differences remain visible so the parity gate can classify them instead of silently hiding them."
File.write(MARKDOWN_PATH, markdown.join("\n") + "\n")

puts "Generated #{JSON_PATH}"
puts "Generated #{MARKDOWN_PATH}"
