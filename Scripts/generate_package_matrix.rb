#!/usr/bin/env ruby

# English: Generate the CocoaPods and SwiftPM parity matrix from current reports.
# Español: Genera la matriz de paridad de CocoaPods y SwiftPM a partir de los informes actuales.
# 中文：根据当前报告生成 CocoaPods 与 SwiftPM 的 parity 矩阵。

require "json"
require "open3"
require "time"

repo_root = File.expand_path("..", __dir__)
report_root = File.join(repo_root, "report", "current")
output_path = File.join(repo_root, "docs", "architecture", "PACKAGE_MATRIX.md")

spm = JSON.parse(File.read(File.join(report_root, "spm_dependency_graph.json")))
pods = JSON.parse(File.read(File.join(report_root, "cocoapods_subspec_graph.json")))
parity = JSON.parse(File.read(File.join(report_root, "module_parity.json")))
version = File.read(File.join(repo_root, "VERSION")).strip
revision = Open3.capture2("git", "rev-parse", "HEAD", chdir: repo_root).first.strip

aliases = {
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

spm_names = spm.fetch("targets", []).reject { |target| target["type"] == "test" }.group_by do |target|
  canonical_name(target.fetch("name"), aliases)
end
pod_names = pods.fetch("subspecs", []).group_by do |subspec|
  canonical_name(subspec.fetch("short_name"), aliases)
end

rows = []
parity.fetch("matched", []).sort.each do |name|
  rows << [name, "A", pod_names.fetch(name, []).map { |item| "PooTools/#{item.fetch("short_name")}" }.sort.uniq,
           spm_names.fetch(name, []).map { |item| item.fetch("name") }.sort.uniq,
           "Keep; review drift"]
end
parity.fetch("pod_only", []).sort.each do |name|
  rows << [name, "B", pod_names.fetch(name, []).map { |item| "PooTools/#{item.fetch("short_name")}" }.sort.uniq,
           [], "Parity decision before 6.0"]
end
parity.fetch("spm_only", []).sort.each do |name|
  rows << [name, "C", [], spm_names.fetch(name, []).map { |item| item.fetch("name") }.sort.uniq,
           "Parity decision before 6.0"]
end

legacy_rows = [
  ["Legacy Network spelling", "D", "PooTools/NetWork", "PooToolsNetWork", "Migrate to Network / PooToolsNetwork"],
  ["Legacy BioID spelling", "D", "PooTools/BilogyID", "—", "Migrate to BioID / PooToolsBioID"],
  ["Legacy Media spelling", "D", "PooTools/MeidaPermission", "—", "Migrate to MediaPermission"],
  ["Legacy typo compile flags", "D", "POOTOOLS_BILOGYID / POOTOOLS_ZIPARCHINE / POOTOOLS_MXMERRICKITMANAGER", "same aliases", "Use canonical flags"]
]

markdown = []
markdown << "<!--"
markdown << "AUTO-GENERATED FILE."
markdown << "DO NOT EDIT MANUALLY."
markdown << ""
markdown << "Generator: Scripts/generate_package_matrix.rb"
markdown << "Source revision: #{revision}"
markdown << "Generated at: #{Time.now.utc.iso8601}"
markdown << "Version source: #{version}"
markdown << "-->"
markdown << ""
markdown << "# CocoaPods / SwiftPM Package Matrix"
markdown << ""
markdown << "A = CocoaPods + SwiftPM, B = CocoaPods only, C = SwiftPM only, D = deprecated compatibility entry, E = merge candidate, F = remove in 6.0."
markdown << ""
markdown << "| Module | Status | CocoaPods | SwiftPM | 6.0 action |"
markdown << "| --- | --- | --- | --- | --- |"
rows.each do |name, status, pod_values, spm_values, action|
  markdown << "| `#{name}` | #{status} | #{pod_values.empty? ? "—" : pod_values.map { |value| "`#{value}`" }.join(" / ")} | #{spm_values.empty? ? "—" : spm_values.map { |value| "`#{value}`" }.join(" / ")} | #{action} |"
end
markdown << ""
markdown << "## Compatibility entries"
markdown << ""
markdown << "| Entry | Status | CocoaPods | SwiftPM | Migration |"
markdown << "| --- | --- | --- | --- | --- |"
legacy_rows.each do |name, status, pod_value, spm_value, migration|
  markdown << "| `#{name}` | #{status} | `#{pod_value}` | `#{spm_value}` | #{migration} |"
end
markdown << ""
markdown << "## Rules"
markdown << ""
markdown << "- New modules must appear in both the manifest and podspec before implementation is considered complete."
markdown << "- A parity exception must be registered with a reason, owner, expiration and 6.0 action in `Scripts/module_registry.json`."
markdown << "- D, E and F entries remain compatibility decisions; they are not permission to delete a public API in 5.x."
markdown << "- The matrix is generated from `report/current`; run `bash Scripts/validate_519_package_tests_docs.sh` after changing package metadata."

File.write(output_path, markdown.join("\n") + "\n")
puts "Generated #{output_path}"
