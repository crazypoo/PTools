# PTools 依赖策略

本策略记录 5.x 后期的依赖边界，目标平台为 iOS 17+、Swift 6+，并同时适用于 SwiftPM、CocoaPods 和 Xcode 工程。

## 日志依赖边界

`PToolsLogging` 是 PTools 日志能力的唯一所有者。它只依赖 Foundation 和 Apple 的 OSLog 能力，日志记录通过 `PTLogger`、`PTLogRecord` 和类型化 Destination 完成。

当前允许的日志后端：

- OSLog：系统诊断输出。
- `PTFileLogDestination`：可选的有界文件写入、轮转和保留。
- `PTMemoryLogDestination`：LocalConsole 与 PTInstruments 共用的有界内存流。

Core、Network、Media、Debug 和 UI 模块可以依赖 `PToolsLogging`，但 `PToolsLogging` 不得依赖 UIKit、Network、媒体模块、Debug UI 或业务模块。

## 5.22 依赖收口

- 5.22.0：从 `Package.swift`、`PooTools.podspec`、`Package.resolved` 和 `Podfile.lock` 移除旧日志第三方依赖。
- 5.22.1：删除旧的文件日志实现、UI sink 兼容实现和影子后端；保留的 PTools 旧入口必须完全转发到 `PTLogger`。
- 5.22.2：完成 API、性能、Debug、Core 依赖图、SwiftPM/CocoaPods parity 和迁移文档复核。

实现路径中不得加入旧日志依赖名称、旧后端类型或影子编译开关。迁移审计文档可以保留历史名称，用于解释升级原因和回滚边界。

## 包管理器一致性

SwiftPM 与 CocoaPods 必须同时满足：

1. Core 通过 `PToolsLogging` 获取日志能力。
2. Logging 子模块只声明 Foundation/OSLog 系统框架。
3. `Package.resolved` 与 `Podfile.lock` 不包含已移除的直接日志依赖。
4. 依赖矩阵、模块矩阵和 `VERSION` 来源保持一致。
5. 任何有意的 parity 差异都要登记原因、负责人、期限和 6.0 处理动作。

## 新依赖准入

新增依赖前必须说明：

- 依赖解决的问题和不能使用系统 API 的原因。
- Swift 6 Strict Concurrency 兼容情况。
- iOS 17 最低系统支持情况。
- SwiftPM、CocoaPods 和 Xcode 三套入口的接入方式。
- 对包体积、启动、内存、隐私和许可证的影响。
- 删除路径、负责人和目标版本。

禁止为了兼容历史实现而重新引入已经移除的日志后端。新日志功能必须扩展 `PTLogger` 或新增符合 `PTLogDestination` 的 PTools 自有实现。

## 质量门禁

每次修改依赖或日志入口都必须执行：

- `bash Scripts/validate_logging_5_22.sh`
- `bash Scripts/validate_quality_scans.sh`
- `swift package dump-package`
- `pod ipc spec PooTools.podspec`
- Xcode Debug/Release Simulator 构建

门禁失败时只能报告为未完成，不能用第三方依赖错误掩盖 PTools 源码结果，也不能创建未通过验证的发布标签。
