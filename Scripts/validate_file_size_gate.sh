#!/usr/bin/env bash

set -euo pipefail

# English: Prevent new God Objects while allowing explicitly owned legacy exceptions.
# Español: Evita nuevos God Objects y permite excepciones heredadas con propietario explícito.
# 中文：阻止新增上帝对象，同时允许登记过负责人和原因的历史例外。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
allowlist="$repo_root/Scripts/file_size_allowlist.txt"
report_dir="$repo_root/report"
mkdir -p "$report_dir"

while IFS='|' read -r path ticket reason; do
  [[ -n "${path:-}" && "${path:0:1}" != "#" ]] || continue
  [[ -n "${ticket:-}" && -n "${reason:-}" ]] || {
    printf 'FAIL: invalid file-size allowlist row: %s|%s|%s\n' "$path" "$ticket" "$reason" >&2
    exit 1
  }
done < "$allowlist"

is_allowlisted() {
  local candidate="$1"
  awk -F'|' -v candidate="$candidate" '
    $1 == candidate && $2 != "" && $3 != "" { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$allowlist"
}

warning_count=0
exception_count=0
failure_count=0
rows=()

while IFS= read -r file; do
  relative="${file#"$repo_root/"}"
  line_count="$(wc -l < "$file" | tr -d ' ')"
  classification="ok"
  if (( line_count > 2000 )); then
    if is_allowlisted "$relative"; then
      classification="hard_limit_allowlisted"
      exception_count=$((exception_count + 1))
    else
      classification="hard_limit_failure"
      failure_count=$((failure_count + 1))
    fi
  elif (( line_count > 1500 )); then
    classification="architecture_exception"
    exception_count=$((exception_count + 1))
  elif (( line_count > 1000 )); then
    classification="warning"
    warning_count=$((warning_count + 1))
  fi
  rows+=("$relative|$line_count|$classification")
done < <(find "$repo_root/PooToolsSource" -type f -name '*.swift' -print | sort)

if (( failure_count > 0 )); then
  printf 'FAIL: %d Swift files exceed 2000 lines without an architecture exception\n' "$failure_count" >&2
  printf '%s\n' "${rows[@]}" | awk -F'|' '$3 == "hard_limit_failure" { print }' >&2
  exit 1
fi

REPORT_DIR="$report_dir" ROWS="$(printf '%s\n' "${rows[@]}")" ruby <<'RUBY'
require "json"

rows = ENV.fetch("ROWS").lines(chomp: true).filter_map do |row|
  path, lines, classification = row.split("|", 3)
  next if path.to_s.empty?
  { "path" => path, "lines" => lines.to_i, "classification" => classification }
end
payload = {
  "schema_version" => 1,
  "thresholds" => { "warning" => 1000, "architecture_exception" => 1500, "hard_failure" => 2000 },
  "files" => rows,
  "warning_count" => rows.count { |row| row["classification"] == "warning" },
  "architecture_exception_count" => rows.count { |row| row["classification"].include?("exception") || row["classification"] == "hard_limit_allowlisted" },
  "hard_limit_allowlisted_count" => rows.count { |row| row["classification"] == "hard_limit_allowlisted" }
}
directory = ENV.fetch("REPORT_DIR")
File.write(File.join(directory, "file_size_5_8.json"), JSON.pretty_generate(payload) + "\n")

markdown = []
markdown << "# 5.8 文件尺寸门禁"
markdown << ""
markdown << "阈值：超过 1000 行警告，超过 1500 行需要架构例外，超过 2000 行必须登记历史例外，否则失败。"
markdown << ""
markdown << "- Warning：#{payload["warning_count"]}"
markdown << "- Architecture exception：#{payload["architecture_exception_count"]}"
markdown << "- Hard-limit allowlisted：#{payload["hard_limit_allowlisted_count"]}"
markdown << ""
markdown << "| 文件 | 行数 | 分类 |"
markdown << "| --- | ---: | --- |"
rows.select { |row| row["classification"] != "ok" }.each do |row|
  markdown << "| `#{row["path"]}` | #{row["lines"]} | #{row["classification"]} |"
end
markdown << "| 无 | 0 | ok |" if rows.none? { |row| row["classification"] != "ok" }
File.write(File.join(directory, "file_size_5_8.md"), markdown.join("\n") + "\n")
RUBY

printf 'PASS: file-size gate (warnings=%d, exceptions=%d)\n' "$warning_count" "$exception_count"
