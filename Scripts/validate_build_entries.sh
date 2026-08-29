#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! rg -q --fixed-strings "$pattern" "$repo_root/$file"; then
    printf 'FAIL: %s (%s)\n' "$description" "$file" >&2
    exit 1
  fi

  printf 'PASS: %s\n' "$description"
}

require_pattern "Package.swift" "// swift-tools-version: 6.0" "SPM tools version is Swift 6.0"
require_pattern "Package.swift" ".iOS(.v17)" "SPM deployment target is iOS 17"
require_pattern "Package.swift" "swiftLanguageModes: [.v6]" "SPM language mode is Swift 6"

require_pattern "PooTools.podspec" "s.platform = :ios, '17.0'" "CocoaPods platform is iOS 17"
require_pattern "PooTools.podspec" "s.swift_versions = ['6.0']" "CocoaPods Swift version is 6.0"
require_pattern "PooTools.podspec" "'IPHONEOS_DEPLOYMENT_TARGET' => '17.0'" "CocoaPods target deployment target is explicit"
require_pattern "PooTools.podspec" "'SWIFT_VERSION' => '6.0'" "CocoaPods target Swift version is explicit"

require_pattern "PooTools.xcodeproj/project.pbxproj" "IPHONEOS_DEPLOYMENT_TARGET = 17.0;" "Xcode deployment target is iOS 17"
require_pattern "PooTools.xcodeproj/project.pbxproj" "SWIFT_VERSION = 6.0;" "Xcode Swift version is 6.0"

bash "$repo_root/Scripts/validate_core_source_contract.sh"

xcode_settings="$(xcodebuild -workspace "$repo_root/PooTools.xcworkspace" -scheme PooTools-Example -showBuildSettings 2>/dev/null)"
if ! rg -q --fixed-strings "IPHONEOS_DEPLOYMENT_TARGET = 17.0" <<< "$xcode_settings"; then
  printf 'FAIL: Xcode scheme resolves to iOS 17\n' >&2
  exit 1
fi
printf 'PASS: Xcode scheme resolves to iOS 17\n'

if ! rg -q --fixed-strings "SWIFT_VERSION = 6.0" <<< "$xcode_settings"; then
  printf 'FAIL: Xcode scheme resolves to Swift 6.0\n' >&2
  exit 1
fi
printf 'PASS: Xcode scheme resolves to Swift 6.0\n'

swift package dump-package >/dev/null
printf 'PASS: Package.swift manifest resolves\n'
