#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

allowed_root_documents=(README.md CHANGELOG.md ROADMAP.md)
for path in "$repo_root"/*.md "$repo_root"/*.json; do
  [[ -e "$path" ]] || continue
  name="${path##*/}"
  case " ${allowed_root_documents[*]} " in
    *" $name "*) ;;
    *)
      printf 'FAIL: versioned or unowned root document remains: %s\n' "$name" >&2
      exit 1
      ;;
  esac
done

required_documents=(
  docs/README.md
  docs/architecture/ARCHITECTURE.md
  docs/architecture/DEBUG_AND_INSTRUMENTS.md
  docs/architecture/DEPENDENCIES.md
  docs/architecture/PACKAGE_MATRIX.md
  docs/architecture/DEPENDENCY_MATRIX.md
  docs/guides/MODULES.md
  docs/guides/EXAMPLE.md
  docs/migration/MIGRATION_6.md
  docs/maintainers/RELEASE.md
  docs/maintainers/QUALITY.md
  docs/maintainers/TEST_MATRIX.md
  docs/maintainers/MODULE_CHECKLIST.md
  api-baseline/README.md
)
for document in "${required_documents[@]}"; do
  [[ -f "$document" ]] || {
    printf 'FAIL: required canonical document is missing: %s\n' "$document" >&2
    exit 1
  }
done

required_current=(
  report/current/dependency_graph.md
  report/current/public_api.json
  report/current/sendable_exceptions.md
  report/current/debug_dependency_graph.md
  report/current/regression_status.md
  report/current/deprecated_api.md
  report/current/large_files.md
  report/current/singletons.md
  report/current/module_parity.md
)
for report in "${required_current[@]}"; do
  [[ -f "$report" ]] || {
    printf 'FAIL: required current report is missing: %s\n' "$report" >&2
    exit 1
  }
done

ruby - "$repo_root" <<'RUBY'
require "json"

repo_root = File.expand_path(ARGV.fetch(0))
markdown_files = Dir.glob(File.join(repo_root, "**", "*.md"), File::FNM_DOTMATCH).reject do |path|
  path.include?("/.git/") || path.include?("/Pods/") || path.include?("/.build/") ||
    path.include?("/build/") || path.include?("/DerivedData")
end

failures = []
markdown_files.each do |file|
  text = File.read(file)
  text.scan(/\[[^\]]*\]\(<?([^)>\s]+)>?\)/).flatten.each do |raw_link|
    link = raw_link.split("#", 2).first
    next if link.empty? || link.start_with?("#", "/", "mailto:") || link.match?(%r{\A(?:https?|ftp|file|codex)://})
    target = File.expand_path(link, File.dirname(file))
    next if File.file?(target) || File.directory?(target)
    failures << "#{file.delete_prefix("#{repo_root}/")}: #{raw_link}"
  end
end

abort "FAIL: broken Markdown links:\n#{failures.join("\n")}" unless failures.empty?

current_dir = File.join(repo_root, "report", "current")
Dir.glob(File.join(current_dir, "**", "*.md")).each do |file|
  text = File.read(file)
  required = ["AUTO-GENERATED FILE.", "Generator:", "Source revision:", "Generated at:"]
  missing = required.reject { |marker| text.include?(marker) }
  abort "FAIL: generated report metadata is incomplete: #{file}: #{missing.join(", ")}" unless missing.empty?
end
Dir.glob(File.join(current_dir, "**", "*.json")).each do |file|
  payload = JSON.parse(File.read(file))
  %w[generator source_revision generated_at].each do |key|
    value = payload[key]
    abort "FAIL: generated JSON metadata is incomplete: #{file}: #{key}" if value.to_s.empty?
  end
rescue JSON::ParserError => error
  abort "FAIL: generated JSON is invalid: #{file}: #{error.message}"
end

puts "PASS: documentation structure, links, and generated-report metadata"
RUBY
