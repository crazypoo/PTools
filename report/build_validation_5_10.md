# PTools 5.10.x 构建与门禁验证

更新时间：2026-09-12

## 已通过

- `PooTools-Example` iOS Simulator Debug 完整 Xcode 构建通过。
  - 日志：`/tmp/ptools-510-debug.G6wiU8/xcodebuild-final-debug-warning-fix-6.log`
- `PooTools-Example` iOS Simulator Release 完整 Xcode 构建通过。
  - 日志：`/tmp/ptools-510-release.qYNzP1/xcodebuild-final-release-warning-fix-2.log`
- Debug / Release 构建日志中未发现 `PooToolsSource` warning 或 error。
- `swift package dump-package`、Core source contract、依赖方向和 Debug Foundation 静态门禁通过。
- `Scripts/validate_build_entries.sh` 通过，确认 SwiftPM、CocoaPods 和 Xcode 使用 iOS 17 / Swift 6 契约。
- `Scripts/validate_quality_scans.sh` 通过；本地化同值项和构建入口 parity 差异仍按既有报告单独提示。
- `git diff --check` 通过。

## 外部诊断

完整 Release 构建中的剩余 warning 来自 Pods、系统工具链或第三方兼容代码，包括 LookinServer、KTVHTTPCache、Harbeth、BlueCryptor、FLEX、SmartCodable 和 Metal toolchain 搜索路径；没有计入 PooTools 源码 warning，也没有修改这些依赖。

## CocoaPods lint

`pod lib lint PooTools.podspec --allow-warnings --skip-tests --no-clean --verbose` 已启动独立临时工程，但 CocoaPods 在依赖目录扫描/复制阶段长时间停留。超过合理时限后主动停止，退出码为 130；完整日志保留在：

`/tmp/ptools-510-pod-lint.log`

该结果是 CocoaPods 验证环境未完成，不代表 PooTools 源码构建失败。发布前仍需在稳定的 CocoaPods 环境重新执行。

## 未执行的运行时验证

- 多 Scene 控制台打开、关闭、断开重连和窗口层级。
- present、sheet、键盘、分屏和横竖屏回归。
- Debug enabled / disabled 的真机 CPU、内存和启动耗时基线。
- 崩溃、泄漏、Inspector 和 MockLocation Collector 的真实宿主行为。

本报告不把静态检查或编译成功当作运行时验收，也不创建版本 tag。
