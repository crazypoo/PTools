# PTools 5.11.x 构建与质量验证记录

日期：2026-09-13

## 构建结果

| 入口 | 配置 | 结果 | 说明 |
| --- | --- | --- | --- |
| CocoaPods workspace / `PooTools-Example` | Debug / iOS Simulator | 通过 | 完整 Xcode 构建，最终复跑使用本地已解析的 SmartCodable 依赖 |
| CocoaPods workspace / `PooTools-Example` | Release / iOS Simulator | 通过 | 完整 Xcode 构建，最终复跑使用本地已解析的 SmartCodable 依赖 |

最终构建日志：

- Debug：`/tmp/ptools-511-debug-membership-fixed-4.log`，xcodebuild exit 0；该次构建已将
  `PTInstruments.swift` 和 `PTInstrumentsUI.swift` 编入 PooTools target。
- Release：`/tmp/ptools-511-release-membership-final.log`，xcodebuild exit 0；该次构建已将
  `PTInstruments.swift` 和 `PTInstrumentsUI.swift` 编入 PooTools target。

源码过滤结果：最终 Debug / Release 日志中没有匹配到
`PooToolsSource` 路径下的 `warning:` 或 `error:`。

## 静态验证

- `bash Scripts/validate_quality_scans.sh`：通过。
- `bash Scripts/validate_build_entries.sh`：通过。
- `bash Scripts/validate_instruments_5_11.sh`：通过。
- `swift package dump-package`：通过。
- `git diff --check`：通过。
- iOS 17 / Swift 6 三套构建契约检查：通过。

质量门禁同时确认 PTInstruments 没有新增 `@unchecked Sendable`、
`nonisolated(unsafe)`、`try!`、`as!`，也没有重复安装 Network、Lifecycle 或 Leak
Collector / swizzle。

## 外部提示

以下提示不是 PooToolsSource 源码错误，本轮不修改第三方依赖或 Pods 源码：

- Pods 的 Metal toolchain search path 不存在。
- SmartCodable 宏声明、SwiftDate、SwifterSwift、lottie-ios、SocketRocket、FLEX、Kakapos
  等第三方或生成头文件存在系统 API / 兼容性警告。
- Pods 的 `Create Symlinks to Header Folders` 脚本未声明输出文件。
- `PooTools-Example` 内 `PTSideController.swift` 仍使用已登记的 `AppDebugMode` 兼容属性。

曾有一次冷构建因 `swift-syntax` 远程更新超时而失败；最终使用已存在且 revision 匹配的本地缓存、
并跳过远程更新后完成 Debug / Release 构建。该依赖网络条件仍应在 CI 环境单独保证。

## 运行时待验证

以下内容不能由 Simulator 构建替代，仍需真实设备和真实宿主执行：

- Disabled / Debug enabled / Recording / Timeline UI 四态 CPU、内存、FPS 和主线程卡顿基线。
- `PooTools-Example`、CrazyDashboard 和至少一个真实业务宿主的导入、导出和多 Scene 回归。
- iOS 17 / iOS 26、横竖屏、Light / Dark、VoiceOver、Reduce Motion / Transparency。
- 长会话容量上限、真实网络摘要和泄漏诊断的实际行为。

因此，5.11.8 / 5.11.9 仍不能仅凭本记录标记为最终性能验收或 6.0 rehearsal 完成；
本记录只确认源码已编译、静态门禁已通过，不能替代真机和真实宿主验证。
