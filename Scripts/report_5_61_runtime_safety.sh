#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

mode="${1:---write}"
case "$mode" in
  --write|--check) ;;
  *) printf 'Usage: %s [--write|--check]\n' "$0" >&2; exit 64 ;;
esac

# English: Generate one worktree-aware safety report for the 5.61.0 release gate.
# Español: Genera un informe de seguridad consciente del árbol de trabajo para la puerta 5.61.0.
# 中文：为 5.61.0 发布门禁生成感知当前工作树的安全报告。
ruby -rjson -rdigest - "${mode}" "$repo_root/Scripts/fatal_error_allowlist.json" "$repo_root/report/current/ptools_5_61_runtime_safety.json" <<'RUBY'
require "fileutils"
require "json"
require "open3"
require "set"
require "time"

mode, allowlist_path, output_path = ARGV
repo_root = Dir.pwd
source_files = Dir.glob(File.join(repo_root, "PooToolsSource/**/*.swift")).sort
allowlist = JSON.parse(File.read(allowlist_path))
allowlisted_paths = allowlist.fetch("rules").map { |rule| rule.fetch("path") }.to_set

def source_line?(line)
  stripped = line.strip
  !stripped.empty? && !stripped.start_with?("//", "*", "/*")
end

def worktree_digest(repo_root)
  stdout, stderr, status = Open3.capture3("ruby", "Scripts/Governance/source_inputs_digest.rb", chdir: repo_root)
  abort "Unable to calculate source tree hash: #{stderr.strip}" unless status.success?
  stdout.strip
end

fatal_entries = []
forceful_entries = []
app_windows_entries = []
unchecked_entries = []
kakapos_entries = []

source_files.each do |absolute_path|
  relative_path = absolute_path.delete_prefix("#{repo_root}/")
  lines = File.readlines(absolute_path, chomp: true)
  lines.each_with_index do |line, index|
    next unless source_line?(line)
    line_number = index + 1
    if line.match?(/fatalError\s*\(/)
      context = lines[[0, index - 8].max..index].join("\n")
      category = if context.match?(/init\??\s*\(coder:/)
                   "PROGRAMMATIC_ONLY"
                 elsif allowlisted_paths.include?(relative_path)
                   "ALLOWLISTED_ABSTRACT_CONTRACT"
                 else
                   "UNCLASSIFIED"
                 end
      fatal_entries << { "path" => relative_path, "line" => line_number, "category" => category, "text" => line.strip }
    end
    forceful_entries << { "path" => relative_path, "line" => line_number, "text" => line.strip } if line.match?(/as!|try!\s*(?!\=)/)
    app_windows_entries << { "path" => relative_path, "line" => line_number, "text" => line.strip } if line.include?("AppWindows!")
    unchecked_entries << { "path" => relative_path, "line" => line_number, "text" => line.strip } if line.include?("@unchecked Sendable")
  end
end

dependency_files = %w[Package.swift Package.resolved PooTools.podspec Scripts/dependency_freeze.json Scripts/module_registry.json]
dependency_files.each do |relative_path|
  next unless File.file?(File.join(repo_root, relative_path))
  File.readlines(File.join(repo_root, relative_path), chomp: true).each_with_index do |line, index|
    kakapos_entries << { "path" => relative_path, "line" => index + 1, "text" => line.strip } if line.match?(/Kakapos/i)
  end
end

source_revision = Open3.capture2("git", "rev-parse", "HEAD", chdir: repo_root).first.strip
report = {
  # English: Identify the generator so release validation can verify provenance.
  # Español: Identifica el generador para que la validación de publicación pueda verificar la procedencia.
  # 中文：记录生成器，便于发布校验验证报告来源。
  "generator" => "Scripts/report_5_61_runtime_safety.sh",
  "schema_version" => 1,
  "baseline" => File.read(File.join(repo_root, "VERSION")).strip,
  "source_revision" => source_revision,
  "source_tree_hash" => worktree_digest(repo_root),
  "generated_at" => Time.now.utc.iso8601,
  "checks" => {
    "kakapos" => { "count" => kakapos_entries.length, "matches" => kakapos_entries },
    "app_windows_force_unwrap" => { "count" => app_windows_entries.length, "matches" => app_windows_entries },
    "forceful_operations" => { "count" => forceful_entries.length, "matches" => forceful_entries },
    "fatal_error" => {
      "count" => fatal_entries.length,
      "unclassified_count" => fatal_entries.count { |entry| entry["category"] == "UNCLASSIFIED" },
      "matches" => fatal_entries
    },
    "unchecked_sendable" => { "count" => unchecked_entries.length, "matches" => unchecked_entries },
    "split_view" => {
      "controller" => File.file?(File.join(repo_root, "PooToolsSource/SplitView/PTSplitViewController.swift")),
      "configuration" => File.file?(File.join(repo_root, "PooToolsSource/SplitView/PTSplitConfiguration.swift"))
    }
  }
}

if mode == "--check"
  abort "Missing runtime safety report: #{output_path}" unless File.file?(output_path)
  current = JSON.parse(File.read(output_path))
  %w[baseline source_tree_hash].each do |key|
    abort "Stale runtime safety report #{key}: expected #{report[key].inspect}, got #{current[key].inspect}" unless current[key] == report[key]
  end
  expected_checks = report.fetch("checks")
  actual_checks = current.fetch("checks")
  abort "Stale runtime safety report checks" unless actual_checks == expected_checks
else
  FileUtils.mkdir_p(File.dirname(output_path))
  File.write(output_path, JSON.pretty_generate(report) + "\n")
  puts "Generated #{output_path}"
end

abort "Unclassified fatalError remains" unless report.fetch("checks").fetch("fatal_error").fetch("unclassified_count").zero?
abort "AppWindows! remains in source" unless report.fetch("checks").fetch("app_windows_force_unwrap").fetch("count").zero?
abort "as!/try! remains in source" unless report.fetch("checks").fetch("forceful_operations").fetch("count").zero?
abort "Kakapos remains in dependency manifests" unless report.fetch("checks").fetch("kakapos").fetch("count").zero?
RUBY
