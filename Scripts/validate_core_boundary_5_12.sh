#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

core_files=(PooToolsSource/PToolsCore/*.swift)
failures=()

for file in "${core_files[@]}"; do
  while IFS= read -r import_line; do
    case "$import_line" in
      "import Foundation"|"import ObjectiveC"|"import os.lock") ;;
      *) failures+=("$file imports a non-Core module: $import_line") ;;
    esac
  done < <(rg '^import ' "$file" || true)

  if rg -n 'UIKit|SwiftUI|Photos|AVFoundation|Alamofire|Kingfisher|SnapKit|Lottie|SmartCodable|KakaJSON|CocoaLumberjack|DeviceKit|@unchecked Sendable|nonisolated\(unsafe\)|try!|as!|DispatchQueue\.main\.sync' "$file"; then
    failures+=("$file contains a forbidden Core boundary symbol")
  fi
done

required_fragments=(
  "s.version     = '5.12.0'"
  "subspec.dependency 'PooTools/PToolsCore'"
  "POOTOOLS_SPLIT_CORE"
  "name: \"PToolsCore\""
  "path: \"PooToolsSource/PToolsCore\""
  "dependencies: [\"PToolsCore\", \"SnapKit\"]"
)

for fragment in "${required_fragments[@]}"; do
  if ! rg -q --fixed-strings "$fragment" PooTools.podspec Package.swift; then
    failures+=("missing Core boundary contract: $fragment")
  fi
done

if ! rg -q '#if canImport\(PToolsCore\)' PooToolsSource/Core/PTUrlChange.swift; then
  failures+=("legacy URL parser is missing its PToolsCore forwarding boundary")
fi

if ! rg -q 'PTMainActorBridge = PToolsCore\.PTMainActorBridge' PooToolsSource/Core/PTUtils+SceneConcurrency.swift; then
  failures+=("legacy MainActor bridge is missing its PToolsCore forwarding boundary")
fi

if ! rg -q 'PTLogEvent = PToolsCore\.PTLogEvent' PooToolsSource/Log/PTNSLog.swift; then
  failures+=("legacy logger is missing its PToolsCore contract forwarding boundary")
fi

if ((${#failures[@]} > 0)); then
  printf 'FAIL: 5.12 Core boundary\n' >&2
  printf ' - %s\n' "${failures[@]}" >&2
  exit 1
fi

printf 'PASS: 5.12 Foundation-only Core boundary (%s files)\n' "${#core_files[@]}"
printf 'INFO: legacy UIKit/third-party compatibility surface remains in PooToolsSource/Core for 5.x API compatibility\n'
