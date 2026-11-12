<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 3f9f7d5b604877bdb4a48d32a53944734c9c5072
Source version: 5.69.0
Source inputs digest: ed60290a1fc9bcf9c6196aef2f4a5f386a8a93a84f766fa6d58cfb4cb854f084
Generator version: 1
Generator: Scripts/report_current_summaries.rb
Generated at: 2026-11-12T02:17:28Z
-->

# PTools 当前 Debug 依赖图

本报告从当前 manifest 和 podspec 过滤 Debug、Console、Inspector、Instrument 相关节点；它不复用旧 milestone 的静态数字。

## SwiftPM

| Target | Path | Internal dependencies |
| --- | --- | --- |
| `PToolsDebugConsoleCore` | `PooToolsSource/PToolsDebugCore` | — |
| `PToolsDebugConsoleCoreTests` | `Tests/PToolsDebugConsoleCoreTests` | `PToolsDebugConsoleCore` |
| `PToolsDebugConsoleUI` | `PooToolsSource/PToolsDebugConsoleUI` | `PToolsOverlay` |
| `PToolsDebugCore` | `PooToolsSource/PToolsDebugCore` | `PToolsDebugConsoleCore` |
| `PToolsDebugCoreTests` | `Tests/PToolsDebugCoreTests` | `PToolsDebugCore`, `PToolsDebugMetricsCore` |
| `PToolsDebugInspectorCore` | `PooToolsSource/PToolsDebugInspectorCore` | `PToolsStudioProtocolCore` |
| `PToolsDebugInspectorCoreTests` | `Tests/PToolsDebugInspectorCoreTests` | `PToolsDebugInspectorCore`, `PToolsStudioProtocolCore` |
| `PToolsDebugInspectorLegacyUI` | `PooToolsSource/Inspector` | `PToolsCore`, `PToolsOverlay`, `PToolsSymbols`, `PToolsUIFoundation`, `ptools` |
| `PToolsDebugInspectorUI` | `PooToolsSource/PToolsDebugInspectorUI` | — |
| `PToolsDebugInventoryCore` | `PooToolsSource/PToolsDebugInventoryCore` | — |
| `PToolsDebugInventoryCoreTests` | `Tests/PToolsDebugInventoryCoreTests` | `PToolsDebugInventoryCore` |
| `PToolsDebugMetricsCore` | `PooToolsSource/PToolsDebugMetricsCore` | — |
| `PToolsDebugMetricsUI` | `PooToolsSource/PToolsDebugMetricsUI` | — |
| `PToolsDebugNetworkCore` | `PooToolsSource` | — |
| `PToolsDebugNetworkCoreTests` | `Tests/PToolsDebugNetworkCoreTests` | `PToolsDebugNetworkCore` |
| `PToolsDebugStorageCore` | `PooToolsSource/Debug` | `PToolsDebugInventoryCore` |
| `PToolsDebugStorageCoreTests` | `Tests/PToolsDebugStorageCoreTests` | `PToolsDebugStorageCore` |
| `PToolsDebugStudioBridge` | `PooToolsSource/DebugStudioBridge` | `PToolsDebugInspectorCore`, `PToolsDebugInspectorUI`, `PToolsDebugNetworkCore`, `PToolsDebugStorageCore`, `PToolsStudioProtocolCore`, `PooToolsDEBUG` |
| `PToolsDebugStudioBridgeTests` | `Tests/PToolsDebugStudioBridgeTests` | `PToolsDebugStudioBridge`, `PooToolsDEBUG` |
| `PToolsDebugTests` | `Tests/PToolsDebugTests` | `PToolsDebugConsoleUI`, `PToolsDebugMetricsUI`, `PooToolsDEBUG`, `PooToolsDEBUGTrackingEyes` |
| `PooToolsDEBUG` | `PooToolsSource` | `PToolsBackgroundTasks`, `PToolsConnectivity`, `PToolsDebugConsoleUI`, `PToolsDebugCore`, `PToolsDebugInspectorLegacyUI`, `PToolsDebugInventoryCore`, `PToolsDebugMetricsCore`, `PToolsDebugMetricsUI`, `PToolsDebugNetworkCore`, `PToolsDebugStorageCore`, `PToolsDeepLink`, `PToolsNotifications`, `PToolsOverlay`, `PToolsRouteCore`, `PToolsStorage`, `PToolsSymbols`, `PooToolsNetWork`, `PooToolsPDF`, `PooToolsSearchBar`, `PooToolsShare`, `ptools` |
| `PooToolsDEBUGTrackingEyes` | `PooToolsSource/WhereIsMyEye` | `PTCameraPermission`, `PooToolsDEBUG`, `ptools` |

## CocoaPods

| Subspec | Local dependencies |
| --- | --- |
| `DEBUG` | `PooTools/BackgroundTasks`, `PooTools/Connectivity`, `PooTools/Core`, `PooTools/DeepLink`, `PooTools/NetWork`, `PooTools/Notifications`, `PooTools/Overlay`, `PooTools/PDF`, `PooTools/RouteCore`, `PooTools/SearchBar`, `PooTools/Share`, `PooTools/Storage`, `PooTools/Symbols` |
| `DEBUG_StudioBridge` | `PooTools/DEBUG` |
| `DEBUG_TrackingEyes` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/DEBUG` |

Debug 运行时是否创建窗口、采样器、sink 或 observer，仍需通过真实宿主回归确认。
