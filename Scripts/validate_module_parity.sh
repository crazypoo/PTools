#!/usr/bin/env bash

set -euo pipefail

# English: Compare the SwiftPM and CocoaPods module contracts without changing source code.
# Español: Compara los contratos de módulos de SwiftPM y CocoaPods sin cambiar el código fuente.
# 中文：比较 SwiftPM 与 CocoaPods 的模块契约，但不修改业务源码。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mode="check"
if [[ "${1:-}" == "--update" ]]; then
  mode="update"
elif [[ "${1:-}" != "" && "${1:-}" != "--check" ]]; then
  printf 'Usage: %s [--check|--update]\n' "${BASH_SOURCE[0]}" >&2
  exit 2
fi

ruby "$repo_root/Scripts/report_spm_dependency_graph.rb"
ruby "$repo_root/Scripts/report_cocoapods_subspec_graph.rb"

ruby - "$repo_root" "$mode" <<'RUBY'
require "digest"
require "json"

repo_root = File.expand_path(ARGV.fetch(0))
mode = ARGV.fetch(1)
spm = JSON.parse(File.read(File.join(repo_root, "report/spm_dependency_graph.json")))
pods = JSON.parse(File.read(File.join(repo_root, "report/cocoapods_subspec_graph.json")))
json_path = File.join(repo_root, "report/module_parity_5_8.json")
markdown_path = File.join(repo_root, "report/module_parity_5_8.md")

# English: Normalize historical names only for comparison; preserve original names in the reports.
# Español: Normaliza solo nombres históricos para comparar; conserva los nombres originales en los informes.
# 中文：仅在比较时归一化历史命名，报告中仍保留原始名称。
ALIASES = {
  "Network" => "NetWork",
  "BioID" => "BilogyID",
  "MediaPermission" => "MeidaPermission",
  "SpeechPermission" => "SpeechRecognizerPermission",
  "Keyboard" => "CustomerNumberKeyboard",
  "DEBUGTrackingEyes" => "DEBUG_TrackingEyes",
  "SmartScreenshot" => "SmartScreenshot"
}.freeze

def canonical_name(name)
  value = name.to_s
  value = value.delete_prefix("PooTools/")
  if value == "ptools"
    value = "Core"
  elsif value.start_with?("PooTools")
    value = value.delete_prefix("PooTools")
  elsif value.start_with?("PT") && value.end_with?("Permission")
    value = value.delete_prefix("PT")
  end
  ALIASES.fetch(value, value)
end

def sorted_unique(values)
  values.map(&:to_s).uniq.sort
end

def deep_sort(value)
  case value
  when Hash
    value.keys.sort.each_with_object({}) { |key, result| result[key] = deep_sort(value[key]) }
  when Array
    value.map { |item| deep_sort(item) }.sort_by { |item| JSON.generate(item) }
  else
    value
  end
end

def spm_source_directories(target)
  sources = target.fetch("sources", [])
  if target["name"] == "ptools"
    sources.map(&:to_s).sort
  else
    path = target["path"].to_s
    if path == "PooToolsSource" && !sources.empty?
      sources.map(&:to_s).sort
    else
      path.empty? ? sources.map(&:to_s).sort : [path.delete_prefix("PooToolsSource/")]
    end
  end
end

def pod_source_directories(subspec)
  subspec.fetch("source_directories", []).map(&:to_s).sort
end

def spm_signature(target)
  {
    "source_directories" => spm_source_directories(target),
    "internal_dependencies" => sorted_unique(target.fetch("internal_dependencies", []).map { |dependency| canonical_name(dependency["name"]) }),
    "third_party_dependencies" => sorted_unique(target.fetch("third_party_dependencies", []).map { |dependency| dependency["package"] || dependency["name"] }),
    "swift_settings" => {
      "defines" => sorted_unique(target.fetch("swift_settings", []).filter_map do |setting|
        setting.dig("kind", "define", "_0")
      end),
      "upcoming_features" => sorted_unique(target.fetch("swift_settings", []).filter_map do |setting|
        setting.dig("kind", "enableUpcomingFeature", "_0")
      end)
    }
  }
end

def pod_signature(subspec)
  conditions = subspec.fetch("pod_target_xcconfig", {})["SWIFT_ACTIVE_COMPILATION_CONDITIONS"].to_s.split
  {
    "source_directories" => pod_source_directories(subspec),
    "internal_dependencies" => sorted_unique(subspec.fetch("local_dependencies", []).map { |name| canonical_name(name) }),
    "third_party_dependencies" => sorted_unique(subspec.fetch("third_party_dependencies", [])),
    "swift_settings" => {
      "defines" => sorted_unique(conditions),
      "upcoming_features" => []
    }
  }
end

spm_targets = spm.fetch("targets", []).each_with_object({}) do |target, result|
  key = canonical_name(target.fetch("name"))
  result[key] = { "original_name" => target.fetch("name"), "signature" => spm_signature(target) }
end

pod_subspecs = pods.fetch("subspecs", []).each_with_object({}) do |subspec, result|
  key = canonical_name(subspec.fetch("short_name"))
  result[key] = { "original_name" => subspec.fetch("short_name"), "signature" => pod_signature(subspec) }
end

# English: Aggregate products separately so convenience bundles do not look like missing feature modules.
# Español: Agrupa los productos agregados por separado para no confundirlos con módulos ausentes.
# 中文：单独记录整合产品，避免把它们误判为缺失的功能模块。
spm_product_names = spm.fetch("products", []).map { |product| product["name"] }.sort
pod_names = pod_subspecs.keys
spm_names = spm_targets.keys
matched = (spm_names & pod_names).sort
spm_only = (spm_names - pod_names).sort
pod_only = (pod_names - spm_names).sort

source_drift = []
dependency_drift = []
settings_drift = []
matched.each do |name|
  spm_signature_value = spm_targets.fetch(name).fetch("signature")
  pod_signature_value = pod_subspecs.fetch(name).fetch("signature")
  if spm_signature_value["source_directories"] != pod_signature_value["source_directories"]
    source_drift << {
      "module" => name,
      "spm" => spm_signature_value["source_directories"],
      "cocoapods" => pod_signature_value["source_directories"]
    }
  end
  %w[internal_dependencies third_party_dependencies].each do |field|
    next if spm_signature_value[field] == pod_signature_value[field]
    dependency_drift << {
      "module" => name,
      "field" => field,
      "spm" => spm_signature_value[field],
      "cocoapods" => pod_signature_value[field]
    }
  end
  next if spm_signature_value["swift_settings"] == pod_signature_value["swift_settings"]
  settings_drift << {
    "module" => name,
    "spm" => spm_signature_value["swift_settings"],
    "cocoapods" => pod_signature_value["swift_settings"]
  }
end

payload = {
  "schema_version" => 1,
  "generator" => "Scripts/validate_module_parity.sh",
  "spm_products" => spm_product_names,
  "aggregate_products" => {
    "spm" => spm_product_names.select { |name| name == "PooToolsAll" },
    "cocoapods" => pod_subspecs.values.map { |item| item["original_name"] }.select { |name| name == "InputAll" }
  },
  "matched" => matched,
  "spm_only" => spm_only,
  "pod_only" => pod_only,
  "source_drift" => source_drift,
  "dependency_drift" => dependency_drift,
  "settings_drift" => settings_drift
}
fingerprint = Digest::SHA256.hexdigest(JSON.generate(deep_sort(payload)))
result = payload.merge("status" => "baseline", "fingerprint" => fingerprint)

if mode == "update"
  File.write(json_path, JSON.pretty_generate(result) + "\n")
else
  unless File.file?(json_path)
    warn "FAIL: parity baseline is missing; run Scripts/validate_module_parity.sh --update"
    exit 1
  end
  baseline = JSON.parse(File.read(json_path))
  if baseline["fingerprint"] != fingerprint
    warn "FAIL: SwiftPM/CocoaPods parity drift detected (baseline #{baseline["fingerprint"]}, current #{fingerprint})"
    warn "Run with --update only after reviewing the intentional contract change."
    exit 1
  end
end

markdown = []
markdown << "# SwiftPM / CocoaPods Module Parity"
markdown << ""
markdown << "- Status: `baseline`"
markdown << "- Fingerprint: `#{fingerprint}`"
markdown << "- Matched modules: `#{matched.length}`"
markdown << "- SwiftPM-only modules: `#{spm_only.length}`"
markdown << "- CocoaPods-only modules: `#{pod_only.length}`"
markdown << "- Source-directory drift: `#{source_drift.length}`"
markdown << "- Dependency drift: `#{dependency_drift.length}`"
markdown << "- Swift setting / macro drift: `#{settings_drift.length}`"
markdown << ""
markdown << "## Classification"
markdown << ""
markdown << "| Class | Modules / count |"
markdown << "| --- | --- |"
markdown << "| Matched | #{matched.map { |name| "`#{name}`" }.join(", ")} |"
markdown << "| SwiftPM only | #{spm_only.empty? ? "—" : spm_only.map { |name| "`#{name}`" }.join(", ")} |"
markdown << "| CocoaPods only | #{pod_only.empty? ? "—" : pod_only.map { |name| "`#{name}`" }.join(", ")} |"
markdown << ""
markdown << "## Drift details"
markdown << ""
markdown << "The baseline records existing differences as explicit review items. A later manifest or podspec change must update this baseline only after review."
markdown << ""
markdown << "### Source directories"
markdown << ""
source_drift.each { |item| markdown << "- `#{item["module"]}`: SPM=#{item["spm"].inspect}; CocoaPods=#{item["cocoapods"].inspect}" }
markdown << "- None" if source_drift.empty?
markdown << ""
markdown << "### Dependencies"
markdown << ""
dependency_drift.each { |item| markdown << "- `#{item["module"]}` / `#{item["field"]}`: SPM=#{item["spm"].inspect}; CocoaPods=#{item["cocoapods"].inspect}" }
markdown << "- None" if dependency_drift.empty?
markdown << ""
markdown << "### Swift settings and macros"
markdown << ""
settings_drift.each { |item| markdown << "- `#{item["module"]}`: SPM=#{item["spm"].inspect}; CocoaPods=#{item["cocoapods"].inspect}" }
markdown << "- None" if settings_drift.empty?
markdown << ""
markdown << "## Gate behavior"
markdown << ""
markdown << "- `--update` writes a reviewed baseline."
markdown << "- `--check` (the default) compares the current stable fingerprint and fails on drift."
markdown << "- This gate reports parity; it does not change either build entry or third-party dependencies."
File.write(markdown_path, markdown.join("\n") + "\n")

puts "Parity #{mode}: matched=#{matched.length} spm_only=#{spm_only.length} pod_only=#{pod_only.length} source_drift=#{source_drift.length} dependency_drift=#{dependency_drift.length} settings_drift=#{settings_drift.length}"
RUBY
