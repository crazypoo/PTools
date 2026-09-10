#!/usr/bin/env bash

set -euo pipefail

# English: Verify that SwiftPM permission targets use the small permission core instead of the UI umbrella.
# Español: Verifica que los targets de permisos de SwiftPM usen el núcleo pequeño y no el umbrella de UI.
# 中文：校验 SwiftPM 权限 target 使用轻量权限 Core，而不是完整 UI umbrella。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! rg -q --fixed-strings "$pattern" "$file"; then
    printf 'FAIL: %s (%s)\n' "$description" "$file" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$description"
}

require_pattern "Package.swift" 'name: "PToolsPermissionCore"' "PToolsPermissionCore target is declared"
require_pattern "Package.swift" 'path: "PooToolsSource/PToolsPermissionCore"' "PToolsPermissionCore path is stable"
require_pattern "Package.swift" 'name: "PToolsPermissionUI"' "PToolsPermissionUI target is declared"
require_pattern "Package.swift" 'dependencies: ["PToolsPermissionCore", "PToolsUIFoundation"]' "PToolsPermissionUI depends only on permission/UI foundations"

permission_targets=(
  PTCameraPermission PTLocationPermission PTCalendarPermission PTMotionPermission
  PTTrackingPermission PTRemindersPermission PTSpeechPermission PTHealthPermission
  PTFaceIDPermission PTContactsPermission PTMicPermission PTMediaPermission
  PTBluetoothPermission PTSiriPermission PTNotificationPermission
)

for target in "${permission_targets[@]}"; do
  if ! rg -q "\.target\(name: \"${target}\", dependencies: \[\"PToolsPermissionCore\"\]" Package.swift; then
    printf 'FAIL: %s still depends on the ptools umbrella\n' "$target" >&2
    exit 1
  fi
done
printf 'PASS: all SwiftPM permission targets use PToolsPermissionCore\n'

permission_sources=(
  PooToolsSource/CameraPermission/PTPermissionCamera.swift
  PooToolsSource/LocationPermission/PTPermissionLocation.swift
  PooToolsSource/LocationPermission/PTPermissionLocationAlwaysHandler.swift
  PooToolsSource/LocationPermission/PTPermissionLocationWhenInUseHandler.swift
  PooToolsSource/CalendarPermission/PTPermissionCalendar.swift
  PooToolsSource/MotionPermission/PTPermissionMotion.swift
  PooToolsSource/TrackingPermission/PTPermissionTracking.swift
  PooToolsSource/RemindersPermission/PTPermissionReminders.swift
  PooToolsSource/SpeechPremission/PTPermissionSpeech.swift
  PooToolsSource/HealthPermission/PTPermissionHealth.swift
  PooToolsSource/FaceIDPermission/PTPermissionFaceID.swift
  PooToolsSource/ContactsPermission/PTPermissionContacts.swift
  PooToolsSource/MicPermission/PTPermissionMic.swift
  PooToolsSource/PhotoLibraryPermission/PTPermissionPhotoLibrary.swift
  PooToolsSource/MeidaLibraryPermission/PTPermissionMedia.swift
  PooToolsSource/BluetoothPermission/PTPermissionBluetooth.swift
  PooToolsSource/BluetoothPermission/PTPermissionBluetoothHandler.swift
  PooToolsSource/SiriPermission/PTPermissionSiri.swift
  PooToolsSource/NotificationPermission/PTPermissionNotification.swift
)

for source in "${permission_sources[@]}"; do
  require_pattern "$source" "import PToolsPermissionCore" "${source} imports the split permission core"
done

if rg -n '^import (ptools|Kingfisher|Lottie|Alamofire|SnapKit|SwifterSwift|AttributedString)' \
  PooToolsSource/CameraPermission \
  PooToolsSource/LocationPermission \
  PooToolsSource/CalendarPermission \
  PooToolsSource/MotionPermission \
  PooToolsSource/TrackingPermission \
  PooToolsSource/RemindersPermission \
  PooToolsSource/SpeechPremission \
  PooToolsSource/HealthPermission \
  PooToolsSource/FaceIDPermission \
  PooToolsSource/ContactsPermission \
  PooToolsSource/MicPermission \
  PooToolsSource/MeidaLibraryPermission \
  PooToolsSource/BluetoothPermission \
  PooToolsSource/SiriPermission \
  PooToolsSource/NotificationPermission \
  PooToolsSource/PhotoLibraryPermission; then
  printf 'FAIL: a standalone permission target imports the ptools/UI/network umbrella\n' >&2
  exit 1
fi
printf 'PASS: standalone permission sources do not import the ptools/UI/network umbrella\n'

if rg -n '^import (UIKit|Kingfisher|Lottie|Alamofire|Photos|AVFoundation)' PooToolsSource/PToolsPermissionCore; then
  printf 'FAIL: PToolsPermissionCore imports a UI, network, or system feature framework\n' >&2
  exit 1
fi

printf 'PASS: PToolsPermissionCore remains Foundation-only\n'
