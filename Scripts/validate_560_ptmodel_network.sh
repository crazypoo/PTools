#!/usr/bin/env bash
set -euo pipefail

# English: Validate the 5.60.0 PTModel and typed Network usability contract.
# Español: Valida el contrato de usabilidad PTModel y Network tipado de 5.60.0.
# 中文：校验 5.60.0 PTModel 与类型化 Network 的可用性契约。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  printf 'FAIL [PTMODEL_NETWORK_560] %s\n' "$1" >&2
  exit 1
}

require_text() {
  local pattern="$1"
  local file="$2"
  grep -Fq -- "$pattern" "$file" || fail "$file is missing: $pattern"
}

[[ "$(tr -d '[:space:]' < VERSION)" == "5.60.0" ]] || fail "VERSION must be 5.60.0"
require_text "modelPath: PTJSONPath = .root" PooToolsSource/NetWork/Network.swift
require_text "at path: PTJSONPath = .root" PooToolsSource/NetWork/PTNetworkModelBridge.swift
require_text "modelPathNotFound" PooToolsSource/NetWork/PTNetworkModelBridge.swift
require_text "modelPathTypeMismatch" PooToolsSource/NetWork/PTNetworkModelBridge.swift
require_text "modelPath: \"$.data\"" docs/model/PTMODEL_NETWORK_QUICKSTART_5_60.md
require_text "network.ptmodel-lab" PooTools/PTDemoCatalog.swift
require_text "network.ptmodel-lab" PooTools/PTDemoSelectionCoordinator.swift
require_text "network.ptmodel-lab" Data/demo-registry.yml
[[ -f Tests/PToolsModelTests/PTModelNestedModelTests.swift ]] || fail "nested model regression file is missing"
[[ -f Tests/PToolsNetworkTests/PTNetworkModelPathTests.swift ]] || fail "network path regression file is missing"
[[ -f docs/model/PTMODEL_NETWORK_QUICKSTART_5_60.md ]] || fail "quick start is missing"
[[ -f docs/model/PTMODEL_NETWORK_NESTED_JSON_5_60.md ]] || fail "nested JSON guide is missing"

printf 'PASS [PTMODEL_NETWORK_560] explicit modelPath, nested-model tests, deterministic demo, docs\n'
