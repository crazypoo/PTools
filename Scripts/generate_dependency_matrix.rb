#!/usr/bin/env ruby

# English: Generate a direct-dependency matrix without expanding transitive dependencies.
# Español: Genera una matriz de dependencias directas sin expandir dependencias transitivas.
# 中文：生成直接依赖矩阵，不展开传递依赖。

require "json"
require "open3"
require "time"

repo_root = File.expand_path("..", __dir__)
report_root = File.join(repo_root, "report", "current")
output_path = File.join(repo_root, "docs", "architecture", "DEPENDENCY_MATRIX.md")
spm = JSON.parse(File.read(File.join(report_root, "spm_dependency_graph.json")))
pods = JSON.parse(File.read(File.join(report_root, "cocoapods_subspec_graph.json")))
parity = JSON.parse(File.read(File.join(report_root, "module_parity.json")))
version = File.read(File.join(repo_root, "VERSION")).strip
revision = Open3.capture2("git", "rev-parse", "HEAD", chdir: repo_root).first.strip

aliases = {
  "PToolsLogging" => "Logging",
  "Network" => "NetWork",
  "BioID" => "BilogyID",
  "MediaPermission" => "MeidaPermission",
  "SpeechPermission" => "SpeechRecognizerPermission",
  "Keyboard" => "CustomerNumberKeyboard",
  "DEBUGTrackingEyes" => "DEBUG_TrackingEyes"
}.freeze

def canonical_name(name, aliases)
  value = name.to_s.delete_prefix("PooTools/")
  value = "Core" if value == "ptools"
  value = value.delete_prefix("PooTools") if value.start_with?("PooTools")
  value = value.delete_prefix("PT") if value.start_with?("PT") && value.end_with?("Permission")
  aliases.fetch(value, value)
end

def names(items)
  items.map { |item| item.fetch("name") }.sort.uniq
end

spm_by_name = spm.fetch("targets", []).reject { |target| target["type"] == "test" }.group_by do |target|
  canonical_name(target.fetch("name"), aliases)
end
pod_by_name = pods.fetch("subspecs", []).group_by do |subspec|
  canonical_name(subspec.fetch("short_name"), aliases)
end

module_names = (parity.fetch("matched") + parity.fetch("pod_only") + parity.fetch("spm_only")).uniq.sort
legacy = %w[NetWork BilogyID MeidaPermission SpeechRecognizerPermission CustomerNumberKeyboard DEBUG_TrackingEyes]

rows = module_names.map do |name|
  spm_targets = spm_by_name.fetch(name, [])
  pod_subspecs = pod_by_name.fetch(name, [])
  internal = (spm_targets.flat_map { |target| names(target.fetch("internal_dependencies", [])) } +
              pod_subspecs.flat_map { |subspec| subspec.fetch("local_dependencies", []).map { |value| value.delete_prefix("PooTools/") } }).uniq.sort
  third_party = (spm_targets.flat_map { |target| names(target.fetch("third_party_dependencies", [])) } +
                 pod_subspecs.flat_map { |subspec| subspec.fetch("third_party_dependencies", []) }).uniq.sort
  can_remove = third_party.empty? ? "No direct third-party dependency" : "6.0 review"
  decision = legacy.include?(name) ? "Deprecate alias" : "Keep; review direct drift"
  [name, internal, third_party, can_remove, decision]
end

markdown = []
markdown << "<!--"
markdown << "AUTO-GENERATED FILE."
markdown << "DO NOT EDIT MANUALLY."
markdown << ""
markdown << "Generator: Scripts/generate_dependency_matrix.rb"
markdown << "Source revision: #{revision}"
markdown << "Generated at: #{Time.now.utc.iso8601}"
markdown << "Version source: #{version}"
markdown << "-->"
markdown << ""
markdown << "# Direct Dependency Matrix"
markdown << ""
markdown << "This matrix records direct dependencies only. Transitive dependencies remain owned by the resolved package graphs."
markdown << ""
markdown << "| Module | Direct internal dependencies | Direct third-party dependencies | Can remove | 6.0 decision |"
markdown << "| --- | --- | --- | --- | --- |"
rows.each do |name, internal, third_party, can_remove, decision|
  internal_text = internal.empty? ? "—" : internal.map { |value| "`#{value}`" }.join(", ")
  third_party_text = third_party.empty? ? "—" : third_party.map { |value| "`#{value}`" }.join(", ")
  markdown << "| `#{name}` | #{internal_text} | #{third_party_text} | #{can_remove} | #{decision} |"
end
markdown << ""
markdown << "## Review rules"
markdown << ""
markdown << "- A dependency is removable only after public API, runtime behavior and both package managers are verified."
markdown << "- Third-party entries must not leak through new public API types."
markdown << "- Changes to this matrix must be accompanied by a package graph report and an owner/expiration entry when parity intentionally differs."

File.write(output_path, markdown.join("\n") + "\n")
puts "Generated #{output_path}"
