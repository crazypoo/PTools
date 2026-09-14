# PTools 5.8.9 构建验证记录

## 执行环境

- 日期：2026-09-09（北京时间）
- Xcode：`/Applications/Xcode-beta.app`，版本 27.0
- Workspace：`PooTools.xcworkspace`
- Scheme：`PooTools-Example`
- Destination：iOS Simulator，arm64，iOS 17+
- 签名：关闭，仅执行编译验证

## 执行结果

已执行 Workspace 的 Debug 和 Release 完整构建。两种配置都在外部 Pods 的 `KituraContracts` 编译阶段被阻断：

```text
Pods/KituraContracts/Sources/KituraContracts/BodyFormat.swift:60:23
static property 'json' is not concurrency-safe because non-'Sendable' type 'BodyFormat' may have shared mutable state

Pods/KituraContracts/Sources/KituraContracts/CodableQuery/Extensions.swift:336:5
var '_iso8601Formatter' is not concurrency-safe because it is nonisolated global shared mutable state
```

Release 原始日志：`/tmp/PTools-5.8.9-release.log`。

## 分类结论

- 失败归类：外部依赖的 Swift 6 并发阻断。
- 未修改：Pods 源码、第三方依赖版本、CocoaPods 编译兼容参数。
- PooTools 源码未在该阻断之前报告新的诊断；由于依赖阶段先失败，不能据此宣称完整源码构建通过。
- Pods 的弃用警告、Metal 工具链搜索路径警告和脚本阶段警告单独归类，不计入 PooTools 源码警告门禁。
- 未创建 5.8.9 Tag。

## 后续解除条件

待宿主项目解决 `KituraContracts` 的 Swift 6 兼容性后，重新执行 Debug / Release、CocoaPods lint、模拟器回归和真实设备人工验证，再决定是否推进版本 Tag。

## PTOSLogger 修复后的复验（2026-09-09）

针对 `PTNSLog.swift` 中 `OSLog.Logger` 类型错误完成修复后，重新执行了 `PooTools-Example` 的 Debug / Release 完整 Workspace 构建。两种配置均已编译到 PooTools 源码和 Example 链接阶段，未再发现 `PooToolsSource` 的 error 或 warning。

最终阻断来自外部构建环境：

```text
ld: building for 'iOS-simulator', but linking in object file
Pods/Bugly/Bugly.framework/... built for 'iOS'
clang: error: linker command failed with exit code 1
```

同时报告了外部 Metal 工具链搜索路径缺失。对应日志：

- Debug：`/tmp/PTools-logger-fix-debug.log`
- Release：`/tmp/PTools-logger-fix-release-5.log`

这两个阻断均未通过修改 Pods、第三方二进制或工程配置处理；当前只确认 PooTools 源码已经通过编译，不能将 Example Simulator 链接结果标记为通过。
