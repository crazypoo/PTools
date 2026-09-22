# 5.22 日志迁移指南

适用版本：PTools 5.22.x，最低 iOS 17，Swift 6 Strict Concurrency。

## 变化摘要

5.22.0–5.22.2 完成日志依赖和兼容层收口：SwiftPM、CocoaPods 与锁文件不再引入旧日志第三方依赖，PTools 的日志后端统一由 `PTLogger` 管理。

应用不需要再添加或维护旧日志后端依赖。`PToolsLogging` 只使用 Foundation 和 OSLog，文件日志、LocalConsole、PTInstruments 共享同一份 `PTLogRecord` 数据模型。

## 推荐调用

```swift
PTLogger.info("Request finished", category: .network, metadata: [
    "method": "GET",
    "statusCode": "200"
])

PTLogger.error(error, category: .network)
```

高频日志仍然是同步轻量入口，消息支持惰性构造；文件和内存目标在后台有界处理，不要求业务 API 变成 `async`。

## 旧 PTools 入口

`PTNSLog` 和 `PTNSLogConsole` 继续保留用于 5.x 兼容，但实现已经完全转发到 `PTLogger`。新代码应使用类型化的 `PTLogger` API，以获得稳定的分类、来源、元数据、隐私和等级能力。

`PTOSLogger` 仍可作为 `PTLogging` 适配器使用，内部同样只调用 `PTLogger`。`PTLogFileManager` 名称继续保留为兼容适配器，但不再拥有独立文件写入实现；UI sink 不再提供，LocalConsole 与 PTInstruments 会自动消费共享内存目标。

5.22.1 有意移除了 `PTLogSink` 和 `PTLogSinkCenter`，并删除 `PTLogFileManager` 的独立文件实现。`PTLogFileManager` 旧符号仍由 PTLogger-only 兼容适配器提供。如果宿主直接使用已删除的 sink 符号，应迁移到 `PTLogger` 的 destination、`PTLogger.exportLogFiles()` 或 `PTMemoryLogDestination` 订阅；这些删除项登记在 `api-baseline/removals_5.22.2.txt`，其他未登记的公开 API 删除仍会被质量门禁阻止。

## 隐私要求

不要在日志消息或 metadata 中直接写入密码、token、Cookie、Authorization、refresh token、私钥或完整请求体。Network 的请求/响应头会经过统一脱敏，但业务层仍应尽量只记录必要摘要。

## 安装和解析

SwiftPM 继续使用 `ptools` 或按需使用 `PToolsLogging` product；CocoaPods 继续使用 `PooTools/Core` 或按需使用 `PooTools/Logging` subspec。更新依赖后验证：

```bash
swift package resolve
pod install --no-repo-update
bash Scripts/validate_logging_5_22.sh
```

如果宿主仍然显式声明旧日志依赖，应在宿主自己的迁移提交中移除，不要通过编译宏重新接回 PTools 的已删除兼容路径。

## 文件导出与 Debug

```swift
let files = await PTLogger.exportLogFiles()
```

LocalConsole 和 PTInstruments 不需要手动安装第二个日志 sink。进入 Debug 页面时由对应模块订阅 `PTMemoryLogDestination`，离开页面时取消订阅；日志目标本身保持有界，避免长时间运行导致内存无限增长。

## 回滚边界

如果宿主暂时无法升级，可以回退到已经验证的 5.21.2；回退时应同时恢复宿主的包解析文件，不能把 5.22.x 的锁文件与旧源码混用。5.22.x 不提供重新启用旧日志后端的兼容开关。
