#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
requested_scope="${1:-all}"

# English: Validate the optional application-infrastructure products without changing the default Core boundary.
# Español: Valida los productos opcionales de infraestructura sin cambiar el límite Core predeterminado.
# 中文：验证可选应用基础设施产品，同时不改变默认 Core 边界。
module_paths() {
    case "$1" in
        database) echo "PToolsDatabaseCore PToolsDatabase" ;;
        auth) echo "PToolsAuthCore PToolsAuth" ;;
        sync) echo "PToolsSyncCore PToolsSync" ;;
        transfer) echo "PToolsTransferCore PToolsTransfer" ;;
        storekit) echo "PToolsStoreKit" ;;
        observability) echo "PToolsObservabilityCore PToolsObservability" ;;
        web|webbridge) echo "PToolsWebCore PToolsWebBridge PToolsWeb" ;;
        map) echo "PToolsMapCore PToolsMap" ;;
        integrity) echo "PToolsAppIntegrity" ;;
        remote-config) echo "PToolsConfiguration" ;;
        realtime) echo "PToolsRealtimeCore PToolsRealtime" ;;
    esac
}

if [[ "$requested_scope" != "all" ]]; then
    case "$requested_scope" in
        database|auth|sync|transfer|storekit|observability|web|webbridge|map|integrity|remote-config|realtime) ;;
        *)
            echo "FAIL: unknown application infrastructure scope: $requested_scope" >&2
            exit 2
            ;;
    esac
fi

scopes=(database auth sync transfer storekit observability webbridge map integrity remote-config realtime)
if [[ "$requested_scope" != "all" ]]; then
    scopes=("$requested_scope")
fi

for scope in "${scopes[@]}"; do
    for module in $(module_paths "$scope"); do
        if [[ ! -d "$repo_root/PooToolsSource/$module" ]]; then
            echo "FAIL: missing source directory PooToolsSource/$module" >&2
            exit 1
        fi
    done
done

if ! grep -q 'swiftLanguageModes: \[\.v6\]' "$repo_root/Package.swift"; then
    echo "FAIL: Package.swift is not configured for Swift 6" >&2
    exit 1
fi
if ! grep -q "platforms:.*iOS.*17\|\.iOS(.*17" "$repo_root/Package.swift"; then
    echo "FAIL: Package.swift does not declare iOS 17" >&2
    exit 1
fi

for forbidden in 'try!' 'as!' 'nonisolated(unsafe)'; do
    matches="$(grep -R -n -E --exclude='*.md' --exclude-dir='.build' --exclude-dir='Pods' "$forbidden" "$repo_root/PooToolsSource/PToolsDatabase" "$repo_root/PooToolsSource/PToolsDatabaseCore" "$repo_root/PooToolsSource/PToolsAuth" "$repo_root/PooToolsSource/PToolsAuthCore" "$repo_root/PooToolsSource/PToolsSync" "$repo_root/PooToolsSource/PToolsSyncCore" "$repo_root/PooToolsSource/PToolsTransfer" "$repo_root/PooToolsSource/PToolsTransferCore" "$repo_root/PooToolsSource/PToolsStoreKit" "$repo_root/PooToolsSource/PToolsObservability" "$repo_root/PooToolsSource/PToolsObservabilityCore" "$repo_root/PooToolsSource/PToolsWeb" "$repo_root/PooToolsSource/PToolsWebBridge" "$repo_root/PooToolsSource/PToolsWebCore" "$repo_root/PooToolsSource/PToolsMap" "$repo_root/PooToolsSource/PToolsMapCore" "$repo_root/PooToolsSource/PToolsAppIntegrity" "$repo_root/PooToolsSource/PToolsRealtime" "$repo_root/PooToolsSource/PToolsRealtimeCore" 2>/dev/null || true)"
    if [[ -n "$matches" ]]; then
        echo "FAIL: forbidden $forbidden in application infrastructure:" >&2
        echo "$matches" >&2
        exit 1
    fi
done

python3 - "$repo_root" "$requested_scope" <<'PY'
import json
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
scope = sys.argv[2]
package = (root / "Package.swift").read_text(encoding="utf-8")
podspec = (root / "PooTools.podspec").read_text(encoding="utf-8")
registry_data = json.loads((root / "Scripts/module_registry.json").read_text(encoding="utf-8"))
registry = registry_data["modules"]
expected = {
    "database": ("PToolsDatabaseCore", "PToolsDatabase"),
    "auth": ("PToolsAuthCore", "PToolsAuth"),
    "sync": ("PToolsSyncCore", "PToolsSync"),
    "transfer": ("PToolsTransferCore", "PToolsTransfer"),
    "storekit": ("PToolsStoreKit",),
    "observability": ("PToolsObservabilityCore", "PToolsObservability"),
    "web": ("PToolsWebCore", "PToolsWebBridge", "PToolsWeb"),
    "webbridge": ("PToolsWebCore", "PToolsWebBridge", "PToolsWeb"),
    "map": ("PToolsMapCore", "PToolsMap"),
    "integrity": ("PToolsAppIntegrity",),
    "remote-config": ("PToolsConfiguration",),
    "realtime": ("PToolsRealtimeCore", "PToolsRealtime"),
}
scopes = tuple(expected) if scope == "all" else (scope,)
for item in scopes:
    for product in expected[item]:
        if f'.library(name: "{product}"' not in package:
            raise SystemExit(f"missing SwiftPM product: {product}")
        if product not in podspec:
            raise SystemExit(f"missing CocoaPods subspec/source: {product}")
        if not any(entry.get("spm_product") == product for entry in registry):
            raise SystemExit(f"missing module registry entry: {product}")
if re.search(r'PooToolsAll[\s\S]{0,800}PTools(Database|Auth|Sync|Transfer|StoreKit|Observability|Web|Map|AppIntegrity|Realtime)', package):
    raise SystemExit("optional application infrastructure must not enter PooToolsAll")
subprocess.run(["swift", "package", "dump-package"], cwd=root, check=True, stdout=subprocess.DEVNULL)
PY

# English: Build each Foundation-first target when the host platform supports it; UIKit-only transitive products are reported as blockers.
# Español: Construye cada target Foundation-first cuando la plataforma anfitriona lo permite; los productos UIKit transitivos se reportan como bloqueos.
# 中文：在宿主平台支持时逐个构建 Foundation-first target；UIKit 传递依赖问题单独报告为阻断。
package_blocked=0
for scope in "${scopes[@]}"; do
    for target in $(module_paths "$scope"); do
        if [[ "$target" == "PToolsRealtime" ]]; then
            echo "BLOCKED: $target requires an iOS host because PooToolsSocketKit depends on UIKit"
            package_blocked=1
            continue
        fi
        if ! swift build --target "$target" >/tmp/ptools-application-infrastructure-"$target".log 2>&1; then
            if grep -q "unable to resolve module dependency: 'UIKit'" /tmp/ptools-application-infrastructure-"$target".log; then
                echo "BLOCKED: $target requires an iOS host (UIKit is unavailable on macOS)"
                package_blocked=1
            else
                cat /tmp/ptools-application-infrastructure-"$target".log >&2
                exit 1
            fi
        fi
    done
done

if [[ "$requested_scope" == "all" ]]; then
    test_log=/tmp/ptools-application-infrastructure-tests.log
    if ! swift test --filter PToolsApplicationInfrastructureTests >"$test_log" 2>&1; then
        if grep -q "unable to resolve module dependency: 'UIKit'" "$test_log"; then
            echo "BLOCKED: PToolsApplicationInfrastructureTests requires an iOS host (UIKit is unavailable on macOS)"
            package_blocked=1
        else
            cat "$test_log" >&2
            exit 1
        fi
    fi
fi

python3 "$repo_root/Scripts/Example/validate_demo_coverage.py" --check
python3 "$repo_root/Scripts/Docs/audit_docs.py" --check
git -C "$repo_root" diff --check
if [[ "$package_blocked" -ne 0 ]]; then
    echo "BLOCKED: application infrastructure package checks require iOS/Xcode host"
    exit 3
fi
echo "PASS: application infrastructure validation ($requested_scope)"
