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
require "date"
require "json"
require "set"
require "time"

repo_root = File.expand_path(ARGV.fetch(0))
mode = ARGV.fetch(1)
spm = JSON.parse(File.read(File.join(repo_root, "report/current/spm_dependency_graph.json")))
pods = JSON.parse(File.read(File.join(repo_root, "report/current/cocoapods_subspec_graph.json")))
json_path = File.join(repo_root, "report/current/module_parity.json")
markdown_path = File.join(repo_root, "report/current/module_parity.md")

# English: Normalize historical names only for comparison; preserve original names in the reports.
# Español: Normaliza solo nombres históricos para comparar; conserva los nombres originales en los informes.
# 中文：仅在比较时归一化历史命名，报告中仍保留原始名称。
ALIASES = {
  "PToolsLogging" => "Logging",
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

# English: Test targets are validation-only and must not change the shipped module contract.
# Español: Los targets de prueba solo validan el código y no deben cambiar el contrato publicado.
# 中文：测试 target 仅用于验证，不应改变发布模块契约。
spm_targets = spm.fetch("targets", []).reject { |target| target["type"] == "test" }.each_with_object({}) do |target, result|
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

# English: Require every intentional parity exception to carry an owner, reason, and expiry.
# Español: Exige que cada excepción intencional de paridad tenga responsable, motivo y vencimiento.
# 中文：要求每条有意保留的 parity 例外都记录负责人、原因和过期日期。
registry_path = File.join(repo_root, "Scripts/module_registry.json")
unless File.file?(registry_path)
  warn "FAIL: module registry is missing: #{registry_path}"
  exit 1
end
registry = JSON.parse(File.read(registry_path))
expected_metadata = %w[reason owner expiration]
unless registry.fetch("required_drift_metadata", []) == expected_metadata
  warn "FAIL: module registry required_drift_metadata must be #{expected_metadata.inspect}"
  exit 1
end
resolution_defaults = registry.fetch("resolution_defaults")
%w[action target_version].each do |key|
  value = resolution_defaults[key]
  if !value.is_a?(String) || value.strip.empty?
    warn "FAIL: module registry resolution_defaults is missing non-empty #{key}"
    exit 1
  end
end

current_entries = []
spm_only.each { |module_name| current_entries << { "kind" => "spm_only", "module" => module_name } }
pod_only.each { |module_name| current_entries << { "kind" => "pod_only", "module" => module_name } }
source_drift.each { |item| current_entries << item.merge("kind" => "source", "field" => "source_directories") }
dependency_drift.each { |item| current_entries << item.merge("kind" => "dependency") }
settings_drift.each { |item| current_entries << item.merge("kind" => "settings") }

# English: Validate registry shape, metadata, expiry, and the current parity identities.
# Español: Valida la forma, los metadatos, el vencimiento y las identidades actuales de paridad.
# 中文：校验 registry 结构、元数据、过期日期及当前 parity 身份。
allowed_kinds = %w[spm_only pod_only source dependency settings]
validate_entry = lambda do |entry, section|
  unless entry.is_a?(Hash)
    warn "FAIL: #{section} contains a non-object entry"
    exit 1
  end
  kind = entry["kind"].to_s
  module_name = entry["module"].to_s
  valid_section_kind = section == "known_module_only" ? %w[spm_only pod_only] : %w[source dependency settings]
  unless valid_section_kind.include?(kind) && allowed_kinds.include?(kind) && !module_name.empty?
    warn "FAIL: invalid module registry identity in #{section}: #{entry.inspect}"
    exit 1
  end
  expected_metadata.each do |key|
    value = entry[key]
    if !value.is_a?(String) || value.strip.empty?
      warn "FAIL: #{section} #{kind}/#{module_name} is missing non-empty #{key}"
      exit 1
    end
  end
  begin
    expiration = Date.iso8601(entry.fetch("expiration"))
  rescue ArgumentError
    warn "FAIL: #{section} #{kind}/#{module_name} has invalid expiration #{entry["expiration"].inspect}"
    exit 1
  end
  if expiration < Date.today
    warn "FAIL: #{section} #{kind}/#{module_name} has expired metadata #{expiration.iso8601}"
    exit 1
  end
  if kind == "dependency" && entry["field"].to_s.empty?
    warn "FAIL: dependency drift #{module_name} must declare field"
    exit 1
  end
  [kind, module_name, entry["field"].to_s]
end

known_entries = registry.fetch("known_module_only", []).map { |entry| validate_entry.call(entry, "known_module_only") }
known_entries.concat(registry.fetch("known_drift", []).map { |entry| validate_entry.call(entry, "known_drift") })
if known_entries.uniq.length != known_entries.length
  warn "FAIL: module registry contains duplicate identities"
  exit 1
end
known_identity_set = known_entries.to_set
current_identity_set = current_entries.map { |entry| [entry["kind"], entry["module"], entry["field"].to_s] }.to_set
unregistered = current_identity_set - known_identity_set
stale = known_identity_set - current_identity_set
unless unregistered.empty?
  warn "FAIL: new parity drift requires registry reason/owner/expiration: #{unregistered.inspect}"
  exit 1
end
unless stale.empty?
  warn "FAIL: module registry contains stale identities: #{stale.inspect}"
  exit 1
end

payload = {
  "schema_version" => 1,
  "generator" => "Scripts/validate_module_parity.sh",
  "source_revision" => `git -C "#{repo_root}" rev-parse HEAD`.strip,
  "generated_at" => Time.now.utc.iso8601,
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
fingerprint_payload = payload.reject { |key, _value| %w[generator source_revision generated_at].include?(key) }
fingerprint = Digest::SHA256.hexdigest(JSON.generate(deep_sort(fingerprint_payload)))
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
markdown << "<!--"
markdown << "AUTO-GENERATED FILE."
markdown << "DO NOT EDIT MANUALLY."
markdown << ""
markdown << "Generator: #{payload["generator"]}"
markdown << "Source revision: #{payload["source_revision"]}"
markdown << "Generated at: #{payload["generated_at"]}"
markdown << "-->"
markdown << ""
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

# English: Emit a reviewable resolution table with visible ownership for every exception.
# Español: Emite una tabla revisable con responsable visible para cada excepción.
# 中文：生成可审阅的 resolution 表，为每条例外显示负责人。
resolution_path = File.join(repo_root, "report/current/module_parity_resolution.md")
resolution = []
resolution << "<!--"
resolution << "AUTO-GENERATED FILE."
resolution << "DO NOT EDIT MANUALLY."
resolution << ""
resolution << "Generator: #{payload["generator"]}"
resolution << "Source revision: #{payload["source_revision"]}"
resolution << "Generated at: #{payload["generated_at"]}"
resolution << "-->"
resolution << ""
resolution << "# Module Parity Resolution"
resolution << ""
resolution << "- Registry: `Scripts/module_registry.json`"
resolution << "- Current exceptions: `#{current_entries.length}`"
resolution << "- Policy: new or changed parity exceptions must be registered with reason, owner, and expiration; action and target version use reviewed registry defaults unless a more specific entry is added."
resolution << ""
resolution << "| Module | SPM dependency / value | Pod dependency / value | Reason | Action | Owner | Target version | Expiration |"
resolution << "| --- | --- | --- | --- | --- | --- | --- | --- |"
registry_by_identity = (registry.fetch("known_module_only", []) + registry.fetch("known_drift", [])).each_with_object({}) do |entry, result|
  result[[entry["kind"], entry["module"], entry["field"].to_s]] = entry
end
current_entries.sort_by { |entry| [entry["kind"], entry["module"], entry["field"].to_s] }.each do |entry|
  metadata = registry_by_identity.fetch([entry["kind"], entry["module"], entry["field"].to_s])
  spm_value = entry.key?("spm") ? entry["spm"] : "—"
  pod_value = entry.key?("cocoapods") ? entry["cocoapods"] : "—"
  values = [
    entry["module"],
    spm_value,
    pod_value,
    metadata["reason"],
    metadata.fetch("action", resolution_defaults["action"]),
    metadata["owner"],
    metadata.fetch("target_version", resolution_defaults["target_version"]),
    metadata["expiration"]
  ]
  values = values.map { |value| value.is_a?(Array) || value.is_a?(Hash) ? JSON.generate(value) : value }
  resolution << "| #{values.map { |value| value.to_s.gsub("|", "\\\\|") }.join(" | ")} |"
end
File.write(resolution_path, resolution.join("\n") + "\n")

puts "Parity #{mode}: matched=#{matched.length} spm_only=#{spm_only.length} pod_only=#{pod_only.length} source_drift=#{source_drift.length} dependency_drift=#{dependency_drift.length} settings_drift=#{settings_drift.length}"
RUBY
