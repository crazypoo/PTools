#!/usr/bin/env bash

set -euo pipefail

# English: Validate the optional P2 modern-system modules and extension boundaries.
# Español: Valida los módulos opcionales de sistemas modernos de P2 y los límites de extensiones.
# 中文：校验可选 P2 现代系统模块及扩展目标边界。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

modules=(Configuration Feedback Audio AppIntents WidgetCore Activities)
for module in "${modules[@]}"; do
    directory="PTools${module}"
    [[ -d "PooToolsSource/$directory" ]] || { printf 'FAIL: missing P2 source directory %s\n' "$directory" >&2; exit 1; }
    rg -q --fixed-strings ".library(name: \"PTools${module}\", targets: [\"PTools${module}\"] )" Package.swift 2>/dev/null \
        || rg -q --fixed-strings ".library(name: \"PTools${module}\", targets: [\"PTools${module}\"]" Package.swift \
        || { printf 'FAIL: missing SwiftPM product PTools%s\n' "$module" >&2; exit 1; }
    rg -q --fixed-strings "s.subspec '$module'" PooTools.podspec \
        || { printf 'FAIL: missing CocoaPods subspec %s\n' "$module" >&2; exit 1; }
done

unsafe_concurrency="$(rg -n --glob '*.swift' '@unchecked Sendable|nonisolated\(unsafe\)' \
    PooToolsSource/PToolsConfiguration PooToolsSource/PToolsFeedback PooToolsSource/PToolsAudio \
    PooToolsSource/PToolsAppIntents PooToolsSource/PToolsWidgetCore PooToolsSource/PToolsActivities || true)"
# English: ActivityKit's legacy generic values are allowed only through the named system-boundary box.
# Español: Los valores genéricos heredados de ActivityKit solo se permiten mediante la caja de límite del sistema con nombre.
# 中文：ActivityKit 的旧版泛型值只能通过指定名称的系统边界包装器保留。
unregistered_unsafe="$(printf '%s\n' "$unsafe_concurrency" | rg -v 'PTActivityKitSendableBox' || true)"
if [[ -n "$unregistered_unsafe" ]]; then
    printf '%s\n' "$unregistered_unsafe"
    printf 'FAIL: P2 modules introduce an unregistered unsafe concurrency escape\n' >&2
    exit 1
fi

if rg -n --glob '*.swift' 'import (Alamofire|Kingfisher|SnapKit|SmartCodable|KakaJSON|PooToolsNetWork|PooToolsDEBUG)' \
    PooToolsSource/PToolsConfiguration PooToolsSource/PToolsFeedback PooToolsSource/PToolsAudio \
    PooToolsSource/PToolsAppIntents PooToolsSource/PToolsWidgetCore PooToolsSource/PToolsActivities; then
    printf 'FAIL: P2 modules depend on a feature or third-party runtime\n' >&2
    exit 1
fi

if rg -n --glob '*.swift' 'import UIKit|import SwiftUI|UIApplication\.shared|keyWindow' PooToolsSource/PToolsWidgetCore; then
    printf 'FAIL: WidgetCore is not extension-safe\n' >&2
    exit 1
fi

require_pattern() {
    rg -q --fixed-strings "$2" "$1" || { printf 'FAIL: %s\n' "$3" >&2; exit 1; }
    printf 'PASS: %s\n' "$3"
}

require_pattern PooToolsSource/PToolsConfiguration/PTConfiguration.swift 'public struct PTConfigKey' 'typed configuration key exists'
require_pattern PooToolsSource/PToolsConfiguration/PTConfiguration.swift 'public protocol PTConfigurationProvider' 'remote provider is vendor-neutral'
require_pattern PooToolsSource/PToolsConfiguration/PTConfiguration.swift 'public struct PTConfigurationSnapshot' 'configuration snapshot exists'
require_pattern PooToolsSource/PToolsFeedback/PTFeedback.swift 'public enum PTFeedbackEvent' 'semantic feedback events exist'
require_pattern PooToolsSource/PToolsFeedback/PTFeedback.swift 'CHHapticEngine.capabilitiesForHardware' 'haptic capability uses CoreHaptics'
require_pattern PooToolsSource/PToolsAudio/PTAudio.swift 'public final class PTAudioSessionCoordinator' 'audio session coordinator exists'
require_pattern PooToolsSource/PToolsAudio/PTAudio.swift 'public final class PTAudioRecorder' 'audio recorder exists'
require_pattern PooToolsSource/PToolsAudio/PTAudio.swift 'public struct PTAudioWaveform' 'audio waveform value exists'
require_pattern PooToolsSource/PToolsAppIntents/PTAppIntents.swift 'public final class PTAppIntentRouteBridge' 'AppIntent route bridge exists'
require_pattern PooToolsSource/PToolsAppIntents/PTAppIntents.swift 'source: .appIntent' 'AppIntent requests preserve route source'
require_pattern PooToolsSource/PToolsWidgetCore/PTWidgetCore.swift 'public actor PTWidgetSharedStore' 'Widget shared store requires explicit App Group'
require_pattern PooToolsSource/PToolsWidgetCore/PTWidgetCore.swift 'WidgetCenter.shared' 'Widget reloads use WidgetKit'
require_pattern PooToolsSource/PToolsActivities/PTActivities.swift 'public final class PTActivityCoordinator' 'Activity lifecycle coordinator exists'
require_pattern PooToolsSource/PToolsActivities/PTActivities.swift 'PTActivityUpdatePolicy' 'Activity update policy exists'
require_pattern PooTools.podspec 'APPLICATION_EXTENSION_API_ONLY' 'extension-safe CocoaPods settings are declared'

printf 'P2 modern system module contract OK\n'
