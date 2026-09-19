#!/usr/bin/env bash

set -euo pipefail

# English: Check the P1 architecture seams that are safe to validate statically.
# Español: Comprueba estáticamente los límites de arquitectura P1 que se pueden verificar con seguridad.
# 中文：静态校验 P1 中可以安全验证的架构边界。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

require_fragment() {
  local file="$1"
  local fragment="$2"
  rg -q --fixed-strings "$fragment" "$file" || {
    printf 'FAIL: missing %s in %s\n' "$fragment" "$file" >&2
    exit 1
  }
}

require_fragment PooToolsSource/Core/PTUtils+SceneConcurrency.swift 'public struct Scope'
require_fragment PooToolsSource/Base/PTNavigationConfiguration.swift 'public protocol PTNavigationConfigurable'
require_fragment PooToolsSource/Base/PTCollectionViewTypes.swift 'final class PTCollectionLayoutCacheCoordinator'
require_fragment PooToolsSource/Base/PTCollectionViewTypes.swift 'final class PTCollectionScrollObserverMultiplexer'
require_fragment PooToolsSource/BlackMagic/PTSwiftMethodSwizzle.swift 'public static func registeredRecords()'
require_fragment PooToolsSource/DarkMode/PTThemeProvider.swift 'public struct PTTabBarLayoutAppearance'

tabbar_body="$(awk 'BEGIN { body=0 } /final public class PTTabBarView: UIView/ { body=1 } body { print }' PooToolsSource/Base/PTTabBarView.swift)"
if printf '%s\n' "$tabbar_body" | rg -n 'PTAppBaseConfig\.share\.'; then
  printf 'FAIL: PTTabBarView runtime still reads mutable PTAppBaseConfig after appearance snapshot boundary\n' >&2
  exit 1
fi

bash Scripts/validate_p1_public_api_intent.sh
bash Scripts/validate_p1_performance_registry.sh
bash Scripts/validate_p1_standalone_modules.sh
bash Scripts/validate_p1_dependency_supply_chain.sh

printf 'PASS: P1 architecture closure static contract\n'
