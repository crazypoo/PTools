#!/usr/bin/env bash

set -euo pipefail

# English: Gate the 5.19–5.21 package, dependency, API, test, and documentation contracts.
# Español: Protege los contratos de paquetes, dependencias, API, pruebas y documentación de 5.19–5.21.
# 中文：统一门禁 5.19–5.21 的包、依赖、API、测试和文档契约。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^5\.(19|20|21)\.[0-9]+$ ]] || { printf 'FAIL: package/docs gate requires a 5.19.x, 5.20.x or 5.21.x VERSION, got %s\n' "$version" >&2; exit 1; }

required_files=(
  docs/architecture/PACKAGE_MATRIX.md
  docs/architecture/DEPENDENCY_MATRIX.md
  docs/maintainers/TEST_MATRIX.md
  docs/maintainers/MODULE_CHECKLIST.md
  api-baseline/README.md
  api-baseline/5.18.2/public_api.json
  Scripts/naming_debt_registry.json
)
for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { printf 'FAIL: package/docs required file is missing: %s\n' "$file" >&2; exit 1; }
done

for matrix in docs/architecture/PACKAGE_MATRIX.md docs/architecture/DEPENDENCY_MATRIX.md; do
  rg -q --fixed-strings "Version source: $version" "$matrix" \
    || { printf 'FAIL: matrix is not generated from VERSION: %s\n' "$matrix" >&2; exit 1; }
done
ruby - "docs/architecture/PACKAGE_MATRIX.md" <<'RUBY'
path = ARGV.fetch(0)
rows = File.readlines(path).filter_map do |line|
  match = line.match(/^\| `[^`]+` \| ([A-F]) \|/)
  match && match[1]
end
abort "FAIL: package matrix has no module rows" if rows.empty?
invalid = rows.reject { |status| ("A".."F").include?(status) }
abort "FAIL: package matrix contains an invalid status: #{invalid.inspect}" unless invalid.empty?
abort "FAIL: package matrix does not include a deprecated compatibility status D" unless rows.include?("D")
puts "PASS: package matrix module statuses=#{rows.tally.inspect}"
RUBY
rg -q --fixed-strings '| Module | Direct internal dependencies | Direct third-party dependencies | Can remove | 6.0 decision |' \
  docs/architecture/DEPENDENCY_MATRIX.md \
  || { printf 'FAIL: dependency matrix header is incomplete\n' >&2; exit 1; }

pod_version="$(pod ipc spec PooTools.podspec | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("version")')"
[[ "$pod_version" == "$version" ]] || { printf 'FAIL: podspec version %s != VERSION %s\n' "$pod_version" "$version" >&2; exit 1; }

bash Scripts/validate_test_matrix.sh
bash Scripts/validate_naming_debt.sh
bash Scripts/validate_api_baseline.sh
bash Scripts/validate_deprecated_inventory.sh
swift package dump-package >/dev/null
bash Scripts/validate_module_parity.sh --check
git diff --check

printf 'PASS: PTools package / dependency / tests / docs contracts (%s)\n' "$version"
