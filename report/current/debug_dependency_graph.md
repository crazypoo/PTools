<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_current_summaries.rb
Source revision: 0c4464d6b89fe5b65e29c1dacfa1285400eca29a
Generated at: 2026-09-20T12:31:49Z
-->

# PTools 当前 Debug 依赖图

本报告从当前 manifest 和 podspec 过滤 Debug、Console、Inspector、Instrument 相关节点；它不复用旧 milestone 的静态数字。

## SwiftPM

| Target | Path | Internal dependencies |
| --- | --- | --- |
| `PooToolsDEBUG` | `PooToolsSource` | `PooToolsNetWork`, `PooToolsPDF`, `PooToolsSearchBar`, `PooToolsShare`, `ptools` |
| `PooToolsDEBUGTrackingEyes` | `PooToolsSource/WhereIsMyEye` | `PTCameraPermission`, `PooToolsDEBUG`, `ptools` |

## CocoaPods

| Subspec | Local dependencies |
| --- | --- |
| `DEBUG` | `PooTools/Core`, `PooTools/NetWork`, `PooTools/PDF`, `PooTools/SearchBar`, `PooTools/Share` |
| `DEBUG_TrackingEyes` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/DEBUG` |

Debug 运行时是否创建窗口、采样器、sink 或 observer，仍需通过真实宿主回归确认。
