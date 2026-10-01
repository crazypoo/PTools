#!/usr/bin/env bash

set -euo pipefail

# English: Reject stale current reports instead of treating historical facts as current state.
# Español: Rechaza informes actuales obsoletos en lugar de tratarlos como estado vigente.
# 中文：拒绝过期的 current 报告，避免把历史事实当成当前状态。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
revision="$(git rev-parse HEAD)"
branch="$(git branch --show-current)"
if [[ -z "$branch" ]]; then branch="DETACHED"; fi
report_dir="report/current"
source_inputs_digest="$(ruby Scripts/Governance/source_inputs_digest.rb)"
export SOURCE_INPUTS_DIGEST="$source_inputs_digest"

[[ -d "$report_dir" ]] || { printf 'FAIL [STALE_CURRENT_REPORT] missing %s\n' "$report_dir" >&2; exit 1; }

ruby - "$report_dir" "$version" "$revision" "$branch" <<'RUBY'
require "json"

directory, version, revision, branch = ARGV
required = %w[repository branch sourceRevision sourceVersion generatorVersion sourceInputsDigest]
expected_repository = "crazypoo/PTools"
expected_digest = ENV.fetch("SOURCE_INPUTS_DIGEST")
failures = []

Dir.glob(File.join(directory, "*.json")).sort.each do |path|
  payload = JSON.parse(File.read(path))
  required.each { |key| failures << "#{path}: missing #{key}" unless payload.key?(key) }
  failures << "#{path}: repository mismatch" unless payload["repository"] == expected_repository
  failures << "#{path}: branch mismatch" unless payload["branch"] == branch
  failures << "#{path}: sourceRevision=#{payload["sourceRevision"]}" unless payload["sourceRevision"] == revision
  failures << "#{path}: sourceVersion=#{payload["sourceVersion"]}" unless payload["sourceVersion"] == version
  failures << "#{path}: sourceInputsDigest=#{payload["sourceInputsDigest"]}" unless payload["sourceInputsDigest"] == expected_digest
end

Dir.glob(File.join(directory, "*.md")).sort.each do |path|
  content = File.read(path)
  failures << "#{path}: missing Repository" unless content.include?("Repository: #{expected_repository}")
  failures << "#{path}: missing Branch" unless content.include?("Branch: #{branch}")
  failures << "#{path}: missing Source revision" unless content.include?("Source revision: #{revision}")
  failures << "#{path}: missing Source version" unless content.include?("Source version: #{version}")
  failures << "#{path}: missing or stale Source inputs digest" unless content.include?("Source inputs digest: #{expected_digest}")
  failures << "#{path}: missing Generator version" unless content.include?("Generator version:")
end

abort "FAIL [STALE_CURRENT_REPORT]\n#{failures.join("\n")}" unless failures.empty?
puts "PASS [CURRENT_REPORTS] #{revision} / #{version}"
RUBY
