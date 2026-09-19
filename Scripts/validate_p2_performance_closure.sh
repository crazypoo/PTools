#!/usr/bin/env bash

set -euo pipefail

# English: Validate the Phase P performance, cache, and large-file contracts without replacing Xcode verification.
# Español: Valida los contratos de rendimiento, caché y archivos grandes de la Fase P sin sustituir la verificación de Xcode.
# 中文：校验 Phase P 的性能、缓存和大文件契约，但不替代 Xcode 验证。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

bash Scripts/validate_p1_performance_registry.sh
bash Scripts/validate_file_size_gate.sh >/dev/null
ruby Scripts/report_cache_inventory_5_9.rb >/dev/null
ruby Scripts/report_mainactor_heavy_work.rb >/dev/null

ruby - <<'RUBY'
project = File.read("PooTools.xcodeproj/project.pbxproj")
required = {
  "Network+Download.swift" => 6,
  "Network+Logging.swift" => 6,
  "PTNavigationBarManager.swift" => 6,
  "PTCollectionViewSkeleton.swift" => 6
}
required.each do |name, expected_count|
  actual_count = project.scan(Regexp.new(Regexp.escape(name))).length
  abort "FAIL: #{name} appears #{actual_count} times in the project; expected #{expected_count}" unless actual_count == expected_count
end
puts "PASS: extracted files have one project reference, group entry, build entry and source-phase entry"
RUBY

printf 'PASS: P2 performance, cache and large-file closure static contract\n'
