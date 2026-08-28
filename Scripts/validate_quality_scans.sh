#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

critical_files=(
  PooToolsSource/Router/PTRouter.swift
  PooToolsSource/Picker/PTBasePickerView.swift
  PooToolsSource/Share/PTActivityViewController.swift
  PooToolsSource/Category/UIApplication+PTEX.swift
  PooToolsSource/Contact/PTContact.swift
  PooToolsSource/Debug/PTDebugFunction.swift
  PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift
  PooToolsSource/Animation/PTAnimationFunction.swift
  PooToolsSource/QRCodeScan/PTScanQRController.swift
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

if rg -n --glob '*.swift' 'nonisolated\(unsafe\)' PooToolsSource/CheckUpdate PooToolsSource/Contact PooToolsSource/NFC PooToolsSource/NetWork PooToolsSource/PhotoPicker PooToolsSource/VideoEditor; then
  printf 'FAIL: business-level nonisolated(unsafe) remains in P0 modules\n' >&2
  exit 1
fi

allowlist="Scripts/unchecked_sendable_allowlist.txt"
current_unchecked="$(rg -l --glob '*.swift' '@unchecked Sendable' PooToolsSource | sort)"
allowed_unchecked="$(rg -v '^\s*(#|$)' "$allowlist" | sort)"
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
new_unchecked="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*@unchecked Sendable' | rg -v 'PTSystemPixelBufferBox|PTSystemAVAssetBox|PTLegacyModelTypeBox|PTCodableModelProtocol.*@unchecked Sendable' || true)"
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

printf 'PASS: Swift 6 safety scans\n'
