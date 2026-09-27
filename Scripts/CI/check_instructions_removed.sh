#!/usr/bin/env bash

set -euo pipefail

# English: Block direct references to the removed third-party Instructions package.
# Español: Bloquea referencias directas al paquete Instructions de terceros eliminado.
# 中文：阻止对已移除第三方 Instructions 包的直接引用。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if rg -n --glob '*.swift' --glob '*.m' --glob '*.h' '(^|[[:space:]])import[[:space:]]+Instructions([[:space:]]|$)|CoachMarksController' PooToolsSource PooTools >/tmp/ptools-instructions-imports.txt; then
  cat /tmp/ptools-instructions-imports.txt >&2
  printf 'FAIL: third-party Instructions source reference found\n' >&2
  exit 1
fi

if rg -n --fixed-strings "dependency 'Instructions'" PooTools.podspec Podfile Podfile.lock >/tmp/ptools-instructions-pod.txt; then
  cat /tmp/ptools-instructions-pod.txt >&2
  printf 'FAIL: CocoaPods still declares the third-party Instructions dependency\n' >&2
  exit 1
fi

if rg -n '^  - Instructions \(' Podfile.lock >/tmp/ptools-instructions-lock.txt; then
  cat /tmp/ptools-instructions-lock.txt >&2
  printf 'FAIL: Podfile.lock still resolves the third-party Instructions pod\n' >&2
  exit 1
fi

[[ -d PooToolsSource/Instructions ]] || { printf 'FAIL: native Instructions source is missing\n' >&2; exit 1; }
rg -q --fixed-strings 'PooToolsInstructions' Package.swift || { printf 'FAIL: SwiftPM Instructions product is missing\n' >&2; exit 1; }
printf 'PASS: third-party Instructions dependency removed\n'
