#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.16 Permission and System Services contracts.
# Español: Valida los contratos de Permission y System Services de 5.16.
# 中文：校验 5.16 Permission 与 System Services 契约。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

errors=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    errors=$((errors + 1))
}

require_text() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    if ! rg -q -- "$pattern" "$file"; then
        fail "$description ($file)"
    fi
}

# English: Read the active podspec version so this historical permission gate remains reusable.
# Español: Lee la versión activa del podspec para que esta puerta histórica de permisos siga siendo reutilizable.
# 中文：读取当前 podspec 版本，使这个历史权限门禁可以持续复用。
current_version="$(tr -d '[:space:]' < VERSION)"
if [[ -z "$current_version" ]]; then
    fail "unable to read the active podspec version"
else
    require_text PooTools.podspec "version_path = File.join\\(__dir__, 'VERSION'\\)" "podspec reads VERSION for ${current_version}"
fi
require_text PooToolsSource/PToolsPermissionCore/PTPermissionAuthorizationState.swift "enum PTPermissionAuthorizationState" "normalized permission state"
require_text PooToolsSource/PToolsPermissionCore/PTPermissionCore.swift "makeCompletionOnce" "exactly-once permission bridge"
require_text PooToolsSource/PermissionCore/PTPermission.swift "makeCompletionOnce" "legacy exactly-once permission bridge"
require_text PooToolsSource/PhotoLibraryPermission/PTPermissionPhotoLibrary.swift "case \\.limited: return \\.limited" "Photos limited state"
require_text PooToolsSource/NotificationPermission/PTPermissionNotification.swift "criticalAlertSetting" "notification critical alert snapshot"
require_text PooToolsSource/NotificationPermission/PTPermissionNotification.swift "func requestAuthorization\\(\\) async" "async notification authorization"
require_text PooToolsSource/LocationPermission/PTPermissionLocation.swift "enum PTLocationAccuracyState" "location accuracy state"
require_text PooToolsSource/LocationPermission/PTPermissionLocation.swift "requestTemporaryFullAccuracy" "temporary full accuracy request"
require_text PooToolsSource/BluetoothPermission/PTPermissionBluetooth.swift "func invalidate\\(\\)" "Bluetooth invalidation"
require_text PooToolsSource/IAP/PTIAPManager.swift "isRegisteredWithPaymentQueue" "idempotent IAP observer registration"
require_text PooToolsSource/NFC/PTNFCToolKit.swift "public func invalidate\\(\\)" "NFC session invalidation"
require_text PooToolsSource/Motion/PTMotion.swift "public func invalidate\\(\\)" "motion invalidation"
require_text PooToolsSource/HealthKit/PTHealthKit.swift "statisticsQuery" "HealthKit query ownership"
require_text PooToolsSource/MXMetricKitManager/MetricsManager.swift "isRegistered" "MetricKit subscriber registration"
require_text PooToolsSource/Location/PTGetGPSData.swift "public func invalidate\\(\\)" "location service invalidation"

if rg -n "DispatchSemaphore" PooToolsSource/NotificationPermission/PTPermissionNotification.swift; then
    fail "notification permission still blocks on a semaphore"
fi

# English: Every concrete callback permission request must pass through the once-only bridge.
# Español: Cada solicitud de permiso basada en callback debe pasar por el puente de finalización única.
# 中文：每个 callback 权限请求都必须经过只完成一次的桥接器。
while IFS= read -r file; do
    if ! rg -q "makeCompletionOnce" "$file"; then
        fail "permission request is missing the exactly-once bridge: $file"
    fi
done < <(rg -l --glob '*.swift' "override func request\\(completion" PooToolsSource/*Permission PooToolsSource/MeidaLibraryPermission PooToolsSource/SpeechPremission PooToolsSource/TrackingPermission | sort -u)

new_unsafe="$(git diff --unified=0 -- '*.swift' | rg '^\\+[^+].*(nonisolated\\(unsafe\\)|try!|as!)' | rg -v '^\\+[[:space:]]*(//|/\\*|\\*)' || true)"
if [[ -n "$new_unsafe" ]]; then
    printf '%s\n' "$new_unsafe" >&2
    fail "5.16 changes introduce an unsafe construct"
fi

if ! git diff --check; then
    fail "git diff --check failed"
fi

if (( errors > 0 )); then
    printf '5.16 Permission/System Services validation failed: %d issue(s)\n' "$errors" >&2
    exit 1
fi

printf '5.16 Permission/System Services validation passed.\n'
