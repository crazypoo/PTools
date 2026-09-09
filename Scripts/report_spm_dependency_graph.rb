#!/usr/bin/env ruby

# English: Generate a deterministic SwiftPM target and dependency graph.
# Español: Genera un grafo determinista de targets y dependencias de SwiftPM.
# 中文：生成可重复的 SwiftPM target 与依赖关系图。

require "fileutils"
require "json"
require "open3"
require "set"

REPO_ROOT = File.expand_path("..", __dir__)
REPORT_DIR = File.join(REPO_ROOT, "report")
JSON_PATH = File.join(REPORT_DIR, "spm_dependency_graph.json")
MARKDOWN_PATH = File.join(REPORT_DIR, "spm_dependency_graph.md")

def fail_with(message)
  warn "FAIL: #{message}"
  exit 1
end

stdout, stderr, status = Open3.capture3("swift", "package", "dump-package", chdir: REPO_ROOT)
fail_with("swift package dump-package failed: #{stderr.strip}") unless status.success?

begin
  package = JSON.parse(stdout)
rescue JSON::ParserError => error
  fail_with("unable to parse SwiftPM manifest JSON: #{error.message}")
end

targets = package.fetch("targets", [])
target_names = targets.map { |target| target.fetch("name") }.to_set

def dependency_record(raw, target_names)
  if raw["byName"]
    values = raw.fetch("byName")
    name = values.fetch(0)
    {
      "name" => name,
      "kind" => target_names.include?(name) ? "internal" : "third_party",
      "package" => nil,
      "declaration" => raw
    }
  elsif raw["product"]
    values = raw.fetch("product")
    name = values.fetch(0)
    {
      "name" => name,
      "kind" => target_names.include?(name) ? "internal" : "third_party",
      "package" => values[1],
      "declaration" => raw
    }
  else
    {
      "name" => raw.to_s,
      "kind" => "unknown",
      "package" => nil,
      "declaration" => raw
    }
  end
end

def stable_array(value)
  Array(value).map { |item| item.is_a?(Hash) ? item : item.to_s }.sort_by(&:to_s)
end

target_records = targets.map do |target|
  dependencies = target.fetch("dependencies", []).map { |raw| dependency_record(raw, target_names) }
  {
    "name" => target.fetch("name"),
    "type" => target["type"],
    "path" => target["path"],
    "sources" => stable_array(target["sources"]),
    "resources" => stable_array(target["resources"]),
    "internal_dependencies" => dependencies.select { |item| item["kind"] == "internal" }.sort_by { |item| item["name"] },
    "third_party_dependencies" => dependencies.select { |item| item["kind"] == "third_party" }.sort_by { |item| [item["name"], item["package"].to_s] },
    "unknown_dependencies" => dependencies.select { |item| item["kind"] == "unknown" }.sort_by { |item| item["name"] },
    "swift_settings" => stable_array(target["settings"])
  }
end.sort_by { |target| target["name"] }

core_target = target_records.find { |target| target["name"] == "ptools" }
core_dependencies = core_target ? core_target["third_party_dependencies"] : []

graph = {
  "schema_version" => 1,
  "generator" => "Scripts/report_spm_dependency_graph.rb",
  "package" => package["name"],
  "tools_version" => package["toolsVersion"],
  "swift_language_versions" => stable_array(package["swiftLanguageVersions"]),
  "platforms" => stable_array(package["platforms"]),
  "products" => package.fetch("products", []).map do |product|
    {
      "name" => product["name"],
      "type" => product["type"],
      "targets" => stable_array(product["targets"])
    }
  end.sort_by { |product| product["name"].to_s },
  "package_dependencies" => package.fetch("dependencies", []).sort_by(&:to_s),
  "core_dependency_budget" => {
    "target" => "ptools",
    "direct_third_party_count" => core_dependencies.length,
    "baseline_5_8" => 18,
    "target_end_5_8" => 6,
    "target_end_5_9" => 3,
    "target_6_0_range" => "0-2"
  },
  "targets" => target_records
}

FileUtils.mkdir_p(REPORT_DIR)
File.write(JSON_PATH, JSON.pretty_generate(graph) + "\n")

def dependency_names(target, key)
  target.fetch(key, []).map { |dependency| dependency["name"] }.join(", ").then { |value| value.empty? ? "—" : value }
end

markdown = []
markdown << "# SwiftPM Dependency Graph"
markdown << ""
markdown << "- Schema: `#{graph["schema_version"]}`"
markdown << "- Package: `#{graph["package"]}`"
tools_version = graph["tools_version"].is_a?(Hash) ? graph["tools_version"]["_version"] : graph["tools_version"]
markdown << "- Swift tools: `#{tools_version}`"
markdown << "- Swift language versions: `#{graph["swift_language_versions"].map(&:to_s).join(", ")}`"
markdown << "- Target count: `#{target_records.length}`"
markdown << "- Core direct third-party dependencies: `#{core_dependencies.length}` (baseline `18`)"
markdown << ""
markdown << "## Products"
markdown << ""
markdown << "| Product | Targets |"
markdown << "| --- | --- |"
graph["products"].each do |product|
  markdown << "| `#{product["name"]}` | #{product["targets"].map { |name| "`#{name}`" }.join(", ")} |"
end
markdown << ""
markdown << "## Targets"
markdown << ""
markdown << "| Target | Path | Internal dependencies | Third-party dependencies | Sources / resources |"
markdown << "| --- | --- | --- | --- | --- |"
target_records.each do |target|
  source_count = target["sources"].length
  resource_count = target["resources"].length
  source_summary = "#{source_count} source entries / #{resource_count} resources"
  markdown << "| `#{target["name"]}` | `#{target["path"] || "—"}` | #{dependency_names(target, "internal_dependencies")} | #{dependency_names(target, "third_party_dependencies")} | #{source_summary} |"
end
markdown << ""
markdown << "## Notes"
markdown << ""
markdown << "- This report describes the manifest as resolved by `swift package dump-package`; it does not change the manifest."
markdown << "- Dependencies are classified as internal when their name matches a SwiftPM target; product dependencies retain their package name."
markdown << "- The Core budget is a baseline only. Dependency removal remains a later compatibility-gated task."
File.write(MARKDOWN_PATH, markdown.join("\n") + "\n")

puts "Generated #{JSON_PATH}"
puts "Generated #{MARKDOWN_PATH}"
