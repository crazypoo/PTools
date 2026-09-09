#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

forbidden="$(rg -n --glob '*.swift' \
  'UIApplication\.shared\.windows|UIApplication\.shared\.keyWindow|connectedScenes[[:space:][:print:]]*\.first|delegate\.window' \
  PooToolsSource --glob '!Core/PTUtils+SceneConcurrency.swift' --glob '!Category/UIApplication+PTEX.swift' || true)"

if [[ -n "$forbidden" ]]; then
  printf '%s\n' "$forbidden" >&2
  printf 'FAIL: lifecycle code contains an unscoped window lookup\n' >&2
  exit 1
fi

scene_scan_files="$(rg -l --glob '*.swift' 'connectedScenes' PooToolsSource || true)"
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  case "$file" in
    PooToolsSource/Core/PTUtils+SceneConcurrency.swift|PooToolsSource/Category/UIApplication+PTEX.swift)
      ;;
    *)
      printf 'FAIL: direct connectedScenes access is outside PTSceneContext: %s\n' "$file" >&2
      exit 1
      ;;
  esac
done <<< "$scene_scan_files"

ruby Scripts/report_singletons_5_9.rb >/dev/null
ruby -rjson -e '
  report = JSON.parse(File.read("report/singletons_5_9.json"))
  entries = report.fetch("declarations")
  valid = entries.all? { |entry| %w[A B C D].include?(entry["category"]) }
  abort "FAIL: singleton report contains an unclassified declaration" unless valid
  abort "FAIL: singleton report did not include .share declarations" unless entries.any? { |entry| entry["name"] == "share" }
'

printf 'PASS: 5.9.3 lifecycle window and singleton gates\n'
