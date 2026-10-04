#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# English: Refresh the semantic ownership report from the checked-in manifest.
# Español: Actualiza el informe de propiedad semántica desde el manifiesto versionado.
# 中文：根据仓库内版本化的清单刷新语义能力归属报告。
mkdir -p report/current
ruby -rjson - "$repo_root/Scripts/semantic_capability_ownership.json" "$repo_root/report/current/semantic_capability_ownership.json" <<'RUBY'
require "json"
require "open3"
require "time"

manifest_path, output_path = ARGV
manifest = JSON.parse(File.read(manifest_path))
source_files = Dir.glob("PooToolsSource/**/*.swift").sort
allowed_classifications = %w[MERGE_BACKEND_NOW CANONICAL\ +\ COMPAT LAYERED KEEP_DISTINCT SPECIALIZED_EXCEPTION REMOVE_6]

owners = manifest.fetch("owners").map do |entry|
  classification = entry.fetch("classification")
  abort "Unknown capability classification: #{classification}" unless allowed_classifications.include?(classification)
  matches = entry.fetch("scan_patterns").flat_map do |pattern|
    regexp = Regexp.new(pattern)
    source_files.filter_map do |path|
      next unless File.foreach(path).any? { |line| line.match?(regexp) }
      path
    end
  end.uniq.sort
  entry.merge("matches" => matches, "match_count" => matches.length)
end

report = manifest.merge(
  # English: Keep machine-readable provenance on every generated report.
  # Español: Mantiene la procedencia legible por máquina en cada informe generado.
  # 中文：为每份生成报告保留机器可读的来源信息。
  "generator" => "Scripts/report_semantic_capability_ownership.sh",
  "source_revision" => Open3.capture2("git", "rev-parse", "HEAD", chdir: Dir.pwd).first.strip,
  "generated_at" => Time.now.utc.iso8601,
  "source_file_count" => source_files.length,
  "owners" => owners
)
File.write(output_path, JSON.pretty_generate(report) + "\n")
puts "PASS [SEMANTIC_CAPABILITY_OWNERSHIP] owners=#{owners.length} matched_files=#{owners.sum { |entry| entry.fetch("match_count") }}"
RUBY
