#!/usr/bin/env bash

set -euo pipefail

# English: Validate the P1 capability modules and their dependency direction.
# Español: Valida los módulos de capacidades P1 y la dirección de sus dependencias.
# 中文：校验 P1 能力模块及其依赖方向。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

modules=(Theme Accessibility ContentState Form Bluetooth Documents SimulationCore Simulation)
for module in "${modules[@]}"; do
    directory="PTools${module}"
    [[ -d "PooToolsSource/$directory" ]] || { printf 'FAIL: missing source directory %s\n' "$directory" >&2; exit 1; }
    rg -q --fixed-strings ".library(name: \"PTools${module}\", targets: [\"PTools${module}\"])" Package.swift \
        || { printf 'FAIL: missing SwiftPM product PTools%s\n' "$module" >&2; exit 1; }
    rg -q --fixed-strings "s.subspec '$module'" PooTools.podspec \
        || { printf 'FAIL: missing CocoaPods subspec %s\n' "$module" >&2; exit 1; }
done

if rg -n --glob '*.swift' 'import (Alamofire|PooToolsNetWork|PooToolsDEBUG|LocalConsole)' PooToolsSource/PToolsTheme PooToolsSource/PToolsAccessibility PooToolsSource/PToolsContentState PooToolsSource/PToolsForm PooToolsSource/PToolsSimulationCore PooToolsSource/PToolsSimulation; then
    printf 'FAIL: P1 foundation/UI/simulation modules depend on Network or Debug\n' >&2
    exit 1
fi

if rg -n --glob '*.swift' '@unchecked Sendable|nonisolated\(unsafe\)' PooToolsSource/PToolsTheme PooToolsSource/PToolsAccessibility PooToolsSource/PToolsContentState PooToolsSource/PToolsForm PooToolsSource/PToolsBluetooth PooToolsSource/PToolsDocuments PooToolsSource/PToolsSimulationCore PooToolsSource/PToolsSimulation; then
    printf 'FAIL: P1 modules introduce unchecked or unsafe concurrency declarations\n' >&2
    exit 1
fi

require_pattern() {
    rg -q --fixed-strings "$2" "$1" || { printf 'FAIL: %s\n' "$3" >&2; exit 1; }
    printf 'PASS: %s\n' "$3"
}

require_pattern PooToolsSource/PToolsTheme/PTTheme.swift 'public struct PTTheme: Codable, Hashable, Sendable' 'theme is a Sendable value model'
require_pattern PooToolsSource/PToolsAccessibility/PTAccessibility.swift 'PTAccessibilityFocusCoordinator' 'accessibility focus coordinator exists'
require_pattern PooToolsSource/PToolsContentState/PTContentState.swift 'case offline(previous: Content?)' 'content state keeps offline previous content'
require_pattern PooToolsSource/PToolsForm/PTForm.swift 'public struct PTFormFieldID' 'form fields use stable typed IDs'
require_pattern PooToolsSource/PToolsForm/PTForm.swift 'public func validateField' 'form supports cancellable field validation'
require_pattern PooToolsSource/PToolsBluetooth/PTBluetooth.swift 'public actor PTBluetoothCentral' 'Bluetooth central is actor isolated'
require_pattern PooToolsSource/PToolsDocuments/PTDocuments.swift 'withSecurityScopedAccess' 'documents expose security scoped access'
require_pattern PooToolsSource/PToolsSimulationCore/PTSimulationCore.swift 'public actor PTSimulationClock' 'simulation uses a virtual clock'
require_pattern PooToolsSource/PToolsSimulation/PTSimulation.swift 'guard environment.isEnabled else' 'simulation requires explicit opt in'

printf 'P1 advanced capability module contract OK\n'
