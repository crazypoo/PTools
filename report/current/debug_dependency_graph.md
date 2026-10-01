<!--
Current report metadata.
Repository: crazypoo/PTools
Branch: master
Source revision: 6a3f97d0ab05a4f04ab789c93804c84c787b5da6
Source version: 5.59.0
Generator version: current-report-normalizer
Generated at: 2026-10-01T12:30:41Z
-->

# PTools 当前 Debug 依赖图

本报告从当前 manifest 和 podspec 过滤 Debug、Console、Inspector、Instrument 相关节点；它不复用旧 milestone 的静态数字。

## SwiftPM

| Target | Path | Internal dependencies |
| --- | --- | --- |
| `PToolsDebugTests` | `Tests/PToolsDebugTests` | `PooToolsDEBUG` |
| `PooToolsDEBUG` | `PooToolsSource` | `PToolsBackgroundTasks`, `PToolsConnectivity`, `PToolsDeepLink`, `PToolsNotifications`, `PToolsOverlay`, `PToolsRouteCore`, `PToolsStorage`, `PToolsSymbols`, `PooToolsNetWork`, `PooToolsPDF`, `PooToolsSearchBar`, `PooToolsShare`, `ptools` |
| `PooToolsDEBUGTrackingEyes` | `PooToolsSource/WhereIsMyEye` | `PTCameraPermission`, `PooToolsDEBUG`, `ptools` |

## CocoaPods

| Subspec | Local dependencies |
| --- | --- |
| `DEBUG` | `PooTools/BackgroundTasks`, `PooTools/Connectivity`, `PooTools/Core`, `PooTools/DeepLink`, `PooTools/NetWork`, `PooTools/Notifications`, `PooTools/Overlay`, `PooTools/PDF`, `PooTools/RouteCore`, `PooTools/SearchBar`, `PooTools/Share`, `PooTools/Storage`, `PooTools/Symbols` |
| `DEBUG_TrackingEyes` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/DEBUG` |

Debug 运行时是否创建窗口、采样器、sink 或 observer，仍需通过真实宿主回归确认。
