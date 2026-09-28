<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_current_summaries.rb
Source revision: ac67833be8eb3a4e7c1fdf707677f98ce1722d5e
Generated at: 2026-09-28T03:01:48Z
-->

# PTools 当前 Debug 依赖图

本报告从当前 manifest 和 podspec 过滤 Debug、Console、Inspector、Instrument 相关节点；它不复用旧 milestone 的静态数字。

## SwiftPM

| Target | Path | Internal dependencies |
| --- | --- | --- |
| `PooToolsDEBUG` | `PooToolsSource` | `PToolsBackgroundTasks`, `PToolsConnectivity`, `PToolsDeepLink`, `PToolsNotifications`, `PToolsOverlay`, `PToolsRouteCore`, `PToolsStorage`, `PToolsSymbols`, `PooToolsNetWork`, `PooToolsPDF`, `PooToolsSearchBar`, `PooToolsShare`, `ptools` |
| `PooToolsDEBUGTrackingEyes` | `PooToolsSource/WhereIsMyEye` | `PTCameraPermission`, `PooToolsDEBUG`, `ptools` |

## CocoaPods

| Subspec | Local dependencies |
| --- | --- |
| `DEBUG` | `PooTools/BackgroundTasks`, `PooTools/Connectivity`, `PooTools/Core`, `PooTools/DeepLink`, `PooTools/NetWork`, `PooTools/Notifications`, `PooTools/Overlay`, `PooTools/PDF`, `PooTools/RouteCore`, `PooTools/SearchBar`, `PooTools/Share`, `PooTools/Storage`, `PooTools/Symbols` |
| `DEBUG_TrackingEyes` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/DEBUG` |

Debug 运行时是否创建窗口、采样器、sink 或 observer，仍需通过真实宿主回归确认。
