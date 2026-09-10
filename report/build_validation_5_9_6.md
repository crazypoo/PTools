# PTools 5.9.6 Xcode 构建验证

日期：2026-09-10  
Workspace：`PooTools.xcworkspace`  
Scheme：`PooTools-Example`  
Destination：`generic/platform=iOS Simulator`，`ARCHS=arm64`，`CODE_SIGNING_ALLOWED=NO`  
DerivedData：`/tmp/ptools-5.9.6-dependencies-derived`

## 结果

| 配置 | 结果 | 原因 |
| --- | --- | --- |
| Debug | BLOCKED，xcodebuild exit 65 | 外部 `Pods/KituraContracts` Swift 6 并发诊断：`BodyFormat.json` 和 `_iso8601Formatter` |
| Release | BLOCKED，xcodebuild exit 65 | 外部 `Pods/KituraContracts` Swift 6 并发诊断：`_iso8601Formatter`；同时存在依赖自身的 Codable 警告 |

本次没有发现 `PooToolsSource` 路径下的编译错误或警告；但因为依赖在 PooTools 源码编译前阻断，不能将其表述为完整构建通过。

## 日志

- Debug：`build/xcode-5.9.6-dependencies-debug.log`
- Release：`build/xcode-5.9.6-dependencies-release.log`

## 依赖阻断详情

阻断文件属于 CocoaPods 生成目录：

- `Pods/KituraContracts/Sources/KituraContracts/BodyFormat.swift`
- `Pods/KituraContracts/Sources/KituraContracts/CodableQuery/Extensions.swift`

本轮没有修改 Pods 源码、没有使用全局 Swift 6 覆盖第三方 target，也没有把该问题归因到 Core。
下一步应在依赖升级、Pod target 隔离或 6.0 移除 Swift-JWT 链之间作出明确决策后再复测。
