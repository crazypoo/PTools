#!/usr/bin/env bash

set -euo pipefail

# English: Keep cache and large-file ownership explicit while legacy files are split incrementally.
# Español: Mantén explícitos los responsables de cachés y archivos grandes mientras se dividen gradualmente.
# 中文：在逐步拆分历史大文件期间，明确缓存和大文件的所有者。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

ruby - <<'RUBY'
require "json"

registry = JSON.parse(File.read("Scripts/p1_performance_registry.json"))
registry.fetch("large_files").each do |entry|
  %w[path owner reason next_action].each do |field|
    value = entry[field]
    abort "FAIL: large-file registry is missing #{field}" unless value.is_a?(String) && !value.strip.empty?
  end
  abort "FAIL: large-file path is missing #{entry["path"]}" unless File.file?(entry["path"])
  status = entry.fetch("status")
  abort "FAIL: large-file status is invalid for #{entry["path"]}" unless %w[active closed].include?(status)
  extracted_files = entry.fetch("extracted_files")
  abort "FAIL: extracted_files must be an array for #{entry["path"]}" unless extracted_files.is_a?(Array)
  extracted_files.each do |path|
    abort "FAIL: extracted file is missing #{path}" unless File.file?(path)
  end
end
registry.fetch("caches").each do |entry|
  %w[path owner storage thread count_limit cost_limit disk_limit eviction memory_warning].each do |field|
    value = entry[field]
    abort "FAIL: cache registry is missing #{field}" unless value.is_a?(String) && !value.strip.empty?
  end
  abort "FAIL: cache path is missing #{entry["path"]}" unless File.file?(entry["path"])
end
puts "PASS: performance registry (large_files=#{registry.fetch("large_files").length}, caches=#{registry.fetch("caches").length})"
RUBY
