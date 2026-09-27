#!/usr/bin/env bash
# English: Fail when the removed notification banner dependency or API returns.
# Español: Falla cuando vuelve la dependencia o API eliminada de notification banner.
# 中文：如果已移除的通知条依赖或 API 重新出现，则检查失败。

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scan_paths=(
  "$root_dir/Package.swift"
  "$root_dir/Package.resolved"
  "$root_dir/PooTools.podspec"
  "$root_dir/Podfile.lock"
  "$root_dir/PooToolsSource"
  "$root_dir/Sources"
  "$root_dir/Tests"
)

legacy_pattern='NotificationBannerSwift|Daltron/NotificationBanner|import NotificationBannerSwift|GrowingNotificationBanner|FloatingNotificationBanner|StatusBarNotificationBanner|NotificationBannerQueue|cbpowell/MarqueeLabel'

if rg -n "$legacy_pattern" "${scan_paths[@]}"; then
  printf '%s\n' 'Legacy NotificationBanner or MarqueeLabel usage remains.' >&2
  exit 1
fi

printf '%s\n' 'NotificationBannerSwift and MarqueeLabel removal check passed.'
