#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

checklist="docs/ui/UI_COMPONENTS_5_17.md"
[[ -f "$checklist" ]] || {
  printf 'FAIL: 5.17 UI checklist is missing: %s\n' "$checklist" >&2
  exit 1
}

# English: Keep the 5.17 inventory synchronized with the plan instead of silently dropping a module.
# Español: Mantén el inventario 5.17 sincronizado con el plan para no omitir módulos silenciosamente.
# 中文：让 5.17 清单与计划保持同步，避免静默漏掉模块。
modules=(
  CustomerLabel ProgressBar PageControl Loading HUD Share SearchBar Stepper BankCard
  CheckBox CodeView Country Guide Input Keyboard RateView ScrollBanner Segmented HandSign
  Slider Layout PagingControl Picker TipsView Circle MessageKit NotificationBanner PopoverKit
  Tabbar Instructions Appz Flag WhatsNewsKit iOS17Tips ChinesePinyin DirtyWord Speech Router
  SpeedPanel ZipArchive GCDWebServer WebKit
)

for module in "${modules[@]}"; do
  row_count="$(rg -c "^\\| $module \\|" "$checklist" || true)"
  [[ "$row_count" == "1" ]] || {
    printf 'FAIL: module %s must have exactly one checklist row (actual: %s)\n' "$module" "$row_count" >&2
    exit 1
  }
done
printf 'PASS: 5.17 checklist contains all %s modules exactly once\n' "${#modules[@]}"

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  rg -q --fixed-strings "$pattern" "$repo_root/$file" || {
    printf 'FAIL: %s (%s)\n' "$description" "$file" >&2
    exit 1
  }
  printf 'PASS: %s\n' "$description"
}

require_pattern "PooToolsSource/SearchBar/PTSearchBar.swift" "searchDebounceInterval" "SearchBar debounce contract"
require_pattern "PooToolsSource/SearchBar/PTSearchBar.swift" "searchHandler" "SearchBar async handler contract"
require_pattern "PooToolsSource/SearchBar/PTSearchBar.swift" "public func cancelSearch()" "SearchBar cancellation contract"
require_pattern "PooToolsSource/SearchBar/PTSearchBar.swift" "public func refreshLocalizedText()" "SearchBar localization refresh contract"
require_pattern "PooToolsSource/Picker/PTBasePickerView.swift" "public func show(in hostView: UIView" "Picker embedded presentation contract"
require_pattern "PooToolsSource/Picker/PTBasePickerView.swift" "public func dismiss(animated: Bool)" "Picker dismissal contract"
require_pattern "PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift" "public static func dismissAll" "Alert dismissal contract"
require_pattern "PooToolsSource/Core/PTUtils+SceneConcurrency.swift" "public enum PTSceneContext" "Scene resolution contract"
require_pattern "PooToolsSource/PToolsCore/PTMainActorBridge.swift" "public enum PTMainActorBridge" "MainActor scheduling contract"
require_pattern "PooToolsSource/WebKit/PTHTMLHeightCalculator.swift" "@MainActor" "WebKit MainActor contract"
require_pattern "PooToolsSource/Category/WKWebView+PTEX.swift" "@MainActor" "WKWebView helper MainActor contract"
require_pattern "PooTools.podspec" "s.subspec 'ZipArchive'" "ZipArchive dependency boundary"
require_pattern "PooTools.podspec" "s.subspec 'GCDWebServer'" "GCDWebServer dependency boundary"

# English: New 5.17 changes must not add known crash-prone operations or unsafe actor escapes.
# Español: Los cambios nuevos de 5.17 no deben añadir operaciones propensas a fallos ni escapes inseguros de actor.
# 中文：5.17 新改动不得新增已知高风险操作或不安全的 actor 越界。
new_forceful="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*(try!|as!)' | rg -v '^\+[[:space:]]*(//|/\*|\*)' || true)"
[[ -z "$new_forceful" ]] || {
  printf '%s\nFAIL: 5.17 diff introduces try! or as!\n' "$new_forceful" >&2
  exit 1
}
new_unsafe="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*nonisolated\(unsafe\)' || true)"
[[ -z "$new_unsafe" ]] || {
  printf '%s\nFAIL: 5.17 diff introduces nonisolated(unsafe)\n' "$new_unsafe" >&2
  exit 1
}

git diff --check
printf 'PASS: 5.17 UI source safety and whitespace checks\n'
