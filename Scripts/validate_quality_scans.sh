#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

critical_files=(
  PooToolsSource/Router/PTRouter.swift
  PooToolsSource/Picker
  PooToolsSource/Share/PTActivityViewController.swift
  PooToolsSource/Category/UIApplication+PTEX.swift
  PooToolsSource/Contact/PTContact.swift
  PooToolsSource/Debug/PTDebugFunction.swift
  PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift
  PooToolsSource/Animation/PTAnimationFunction.swift
  PooToolsSource/QRCodeScan/PTScanQRController.swift
  PooToolsSource/ImagePicker
  PooToolsSource/Category/UIScreen+PTEX.swift
  PooToolsSource/Category/UIViewController+Swizzled.swift
  PooToolsSource/LocalConsole/LocalConsole.swift
  PooToolsSource/PhotoPicker
  PooToolsSource/VideoEditor
)

if rg -n 'try!|as!' "${critical_files[@]}"; then
  printf 'FAIL: forceful error/type casts remain in production Swift sources\n' >&2
  exit 1
fi

# Report the complete Core surface without making the legacy inventory a false pass.
# Informa de toda la superficie Core sin convertir el inventario heredado en un falso aprobado.
# 扫描完整 Core 范围，但不把历史问题伪装成新问题或误报为通过。
core_source_dirs=(
  Core Blur ActionsheetAndAlert Base AppStore ApplicationFunction BlackMagic Button
  Category Log StatusBar Protocol Animation PermissionCore PhotoLibraryPermission
  AppDelegate Foundation Language DarkMode Line Badge Rotation Switch Colors Font
  FloatPanel SideMenuControl iCloud
)
core_forceful_report="$(rg -n --glob '*.swift' 'try!|as!' "${core_source_dirs[@]/#/PooToolsSource/}" || true)"
if [[ -n "$core_forceful_report" ]]; then
  printf 'INFO: legacy forceful operations in the complete Core surface:\n' >&2
  printf '%s\n' "$core_forceful_report" | head -120 >&2
fi

if rg -n --glob '*.swift' '(^|[[:space:]])(import Alamofire|Network\.share)' "${core_source_dirs[@]/#/PooToolsSource/}"; then
  printf 'FAIL: Core source must not depend directly on the Network target\n' >&2
  exit 1
fi

bash Scripts/report_duplicate_entries.sh >/dev/null
bash Scripts/validate_localizations.sh
bash Scripts/validate_file_size_gate.sh >/dev/null

# English: Refresh current concurrency and compatibility inventories as part of every quality run.
# Español: Actualiza los inventarios actuales de concurrencia y compatibilidad en cada ejecución de calidad.
# 中文：每次质量扫描都刷新当前并发和兼容性清单。
ruby Scripts/report_concurrency_5_9.rb >/dev/null
ruby Scripts/report_public_api_5_9.rb >/dev/null
ruby Scripts/report_sendable_exceptions.rb >/dev/null
ruby Scripts/report_cache_inventory_5_9.rb >/dev/null
ruby Scripts/report_singletons_5_9.rb >/dev/null
ruby Scripts/report_accessibility_5_9.rb >/dev/null
bash Scripts/validate_concurrency_5_19.sh

# English: Keep the SPM/CocoaPods parity and dependency-direction baselines in the regular quality gate.
# Español: Mantén las líneas base de paridad SPM/CocoaPods y dirección de dependencias en la puerta de calidad.
# 中文：将 SPM/CocoaPods 一致性和依赖方向基线纳入常规质量门禁。
bash Scripts/validate_module_parity.sh --check
bash Scripts/validate_logging_foundation_5_20.sh
bash Scripts/validate_logging_5_21.sh
bash Scripts/validate_logging_5_22.sh
bash Scripts/validate_519_package_tests_docs.sh
bash Scripts/validate_deprecated_inventory.sh
bash Scripts/validate_dependency_direction.sh
bash Scripts/validate_core_boundary_5_12.sh
bash Scripts/validate_ui_5_13_contract.sh
bash Scripts/validate_debug_foundation_5_10.sh
bash Scripts/validate_instruments_5_11.sh
bash Scripts/validate_debug_instruments_5_18.sh
bash Scripts/validate_permission_source_contract.sh
bash Scripts/validate_file_size_gate.sh >/dev/null
ruby Scripts/report_current_summaries.rb >/dev/null

if rg -n --glob '*.swift' 'nonisolated\(unsafe\)' PooToolsSource/CheckUpdate PooToolsSource/Contact PooToolsSource/NFC PooToolsSource/NetWork PooToolsSource/PhotoPicker PooToolsSource/VideoEditor; then
  printf 'FAIL: business-level nonisolated(unsafe) remains in P0 modules\n' >&2
  exit 1
fi

allowlist="Scripts/unchecked_sendable_allowlist.txt"
current_unchecked="$(rg -l --glob '*.swift' '@unchecked Sendable' PooToolsSource | sort)"
allowed_unchecked="$(rg -v '^\s*(#|$)' "$allowlist" | sort)"

# English: Every unchecked boundary must have a category, protection invariant, and replacement plan.
# Español: Cada límite unchecked debe tener una categoría, una invariante de protección y un plan de reemplazo.
# 中文：每个 unchecked 边界都必须登记分类、保护不变量和替代计划。
concurrency_registry="Scripts/concurrency_exception_registry.json"
ruby - "$allowlist" "$concurrency_registry" <<'RUBY'
require "json"

allowlist_path, registry_path = ARGV
allowed = File.readlines(allowlist_path, chomp: true).reject { |line| line.match?(/^\s*(#|$)/) }.sort
registry = JSON.parse(File.read(registry_path))
required_fields = registry.fetch("required_fields")
categories = registry.fetch("category_definitions")
entries = registry.fetch("files")
paths = entries.map { |entry| entry.fetch("path") }.sort
if paths != allowed
  missing = allowed - paths
  extra = paths - allowed
  abort "FAIL: concurrency registry does not match unchecked allowlist; missing=#{missing.inspect} extra=#{extra.inspect}"
end
entries.each do |entry|
  abort "FAIL: concurrency registry entry is missing path" unless entry["path"].is_a?(String) && !entry["path"].strip.empty?
  category = entry.fetch("category")
  abort "FAIL: unknown concurrency registry category #{category.inspect}" unless categories.key?(category)
  abort "FAIL: concurrency registry path is missing #{entry.fetch("path")}" unless File.file?(entry.fetch("path"))
end
categories.each do |category, definition|
  (required_fields - ["category"]).each do |field|
    value = definition[field]
    abort "FAIL: concurrency category #{category} is missing #{field}" unless value.is_a?(String) && !value.strip.empty?
  end
end
actual_unsafe = Dir.glob("PooToolsSource/**/*.swift").select do |path|
  File.read(path).include?("nonisolated(unsafe)")
end.sort
registered_unsafe = registry.fetch("nonisolated_unsafe_files").sort
abort "FAIL: nonisolated(unsafe) registry mismatch; actual=#{actual_unsafe.inspect} registered=#{registered_unsafe.inspect}" unless actual_unsafe == registered_unsafe
RUBY

unlisted_unchecked="$(comm -23 <(printf '%s\n' "$current_unchecked") <(printf '%s\n' "$allowed_unchecked") || true)"
if [[ -n "$unlisted_unchecked" ]]; then
  printf '%s\n' "$unlisted_unchecked" >&2
  printf 'FAIL: @unchecked Sendable declaration is outside the centralized allowlist\n' >&2
  exit 1
fi

# Stale allowlist entries hide drift and must be removed when a declaration disappears.
# Las entradas obsoletas de la lista ocultan cambios y deben eliminarse cuando desaparece una declaración.
# 过期白名单条目会掩盖代码漂移，声明消失后必须同步删除。
stale_unchecked="$(comm -13 <(printf '%s\n' "$current_unchecked") <(printf '%s\n' "$allowed_unchecked") || true)"
if [[ -n "$stale_unchecked" ]]; then
  printf '%s\n' "$stale_unchecked" >&2
  printf 'FAIL: @unchecked Sendable allowlist contains files without a declaration\n' >&2
  exit 1
fi

# Only immutable SDK type metadata and system object boxes may use this narrow compatibility exception.
# Solo los metadatos de tipo inmutables del SDK y las cajas de objetos del sistema pueden usar esta excepción.
# 仅不可变 SDK 类型元数据和系统对象包装器可以使用这个窄范围兼容例外。
# A protocol-only migration can add the new Codable protocol name to an existing
# legacy SDK wrapper line without adding a new unchecked boundary.
# Una migración de protocolo puede añadir el nuevo nombre de protocolo Codable a una línea
# existente de un wrapper legado del SDK sin añadir un nuevo límite unchecked.
# 仅协议迁移可能会把新的 Codable 协议名加入既有 SDK 兼容包装器行，这不代表新增 unchecked 边界。
new_unchecked="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*@unchecked Sendable' | rg -v 'PTSystemPixelBufferBox|PTSystemAVAssetBox|PTLegacyModelTypeBox|PTCodableModelProtocol.*@unchecked Sendable|PTVideoAssetSendableBox' || true)"
if [[ -n "$new_unchecked" ]]; then
  printf '%s\n' "$new_unchecked" >&2
  printf 'FAIL: this change introduces a new @unchecked Sendable declaration\n' >&2
  exit 1
fi

new_unsafe="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*nonisolated\(unsafe\)' || true)"
if [[ -n "$new_unsafe" ]]; then
  printf '%s\n' "$new_unsafe" >&2
  printf 'FAIL: this change introduces a new nonisolated(unsafe) declaration\n' >&2
  exit 1
fi

new_forceful_operations="$(git diff --unified=0 -- '*.swift' \
  | rg '^\+[^+]' \
  | rg 'try!|as!' \
  | rg -v '^\+[[:space:]]*(//|/\*|\*)' || true)"
if [[ -n "$new_forceful_operations" ]]; then
  printf '%s\n' "$new_forceful_operations" >&2
  printf 'FAIL: this change introduces a new try! or as! operation\n' >&2
  exit 1
fi

# English: Include the architecture-closure contracts in the normal quality gate.
# Español: Incluye los contratos de cierre arquitectónico en la puerta de calidad normal.
# 中文：将架构收口契约纳入常规质量门禁。
bash Scripts/validate_p1_architecture_closure.sh

# English: Include Phase P cache, MainActor-heavy-work, and extraction contracts in the normal quality gate.
# Español: Incluye los contratos de caché, trabajo pesado de MainActor y extracción de la Fase P en la puerta normal.
# 中文：将 Phase P 的缓存、MainActor 重活和文件拆分契约纳入常规质量门禁。
bash Scripts/validate_p2_performance_closure.sh
bash Scripts/validate_network_security.sh
bash Scripts/validate_515_media.sh
bash Scripts/validate_516_permission.sh
bash Scripts/validate_517_ui.sh
bash Scripts/validate_search_5_18_1.sh

printf 'PASS: Swift 6 safety scans\n'
