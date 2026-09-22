# CocoaLumberjack 使用审计

本报告在 5.22.2 收口时更新，记录 5.20.x–5.22.x 的日志迁移证据。历史名称只保留在本审计和迁移文档中，用于说明删除范围；交付源码、包清单和锁文件不再包含这些名称。

## 审计范围与命令

实现路径扫描范围：`PooToolsSource`、`Package.swift`、`PooTools.podspec`、`Package.resolved` 和 `Podfile.lock`。已安装的 `Pods`、Git 元数据、构建产物和历史报告不计入 PTools 自有实现结果。

```bash
rg -n -i "CocoaLumberjack|CocoaLumberjackSwift|DDLog|DDFileLogger|DDOSLogger|DDLogger|DDLogMessage|DDLogLevel|dynamicLogLevel" \
  PooToolsSource Package.swift PooTools.podspec Package.resolved Podfile.lock
```

5.22.2 的实现路径扫描结果为零。专用门禁位于 `Scripts/validate_logging_5_22.sh`，迁移文档和本报告不作为源码零引用门禁的扫描范围。

## 结果分类

### A. 日志调用

5.21.0 已将 PTools 内部日志调用收敛到 `PTLogger`。当前 `PTNSLog` 和 `PTNSLogConsole` 继续提供旧 PTools 调用入口，但只负责构造不可变值和转发到 `PTLogger`；没有仿制或保留旧第三方日志 API。

### B. 文件日志

5.22.1 删除了旧的独立 `PooToolsSource/Log/PTLogFileManager.swift` 文件写入实现；历史符号保留为仅转发 `PTLogger` 的兼容适配器。文件日志统一使用 `PTFileLogDestination` 和 `PTLogFileWriter`，继续提供：

- `Library/Caches/PTools/Logs` 下的有界写入；
- 32 KiB 缓冲和异步单消费者；
- 5 MiB/24 小时轮转；
- 7 天、7 个文件和 30 MiB 总容量保留；
- 写入失败降级到 OSLog，不反向触发日志递归；
- `PTLogger.exportLogFiles()` 导出前刷新持久化目标。

### C. 格式化与隐私

`PTLogRecord` 统一保存时间、序列号、等级、分类、来源和元数据。持久化前由 `PTLogRedactor` 对 Authorization、Cookie、token、password、secret 等字段进行脱敏；Network 的请求和响应头使用同一套脱敏规则。

### D. 运行时等级

`PTLogLevel`、全局 minimum level、category level 和采样策略属于 `PToolsLogging` 的类型化契约。Debug 默认允许更详细的等级，Release 默认从 info 开始；旧 PTools 等级由 `PTNSLog` 映射后进入 `PTLogger`。

### E. Debug 数据源

LocalConsole 和 PTInstruments 只消费 `PTMemoryLogDestination` 的不可变快照与多订阅流。两者不再安装独立 sink，不再维护第二条日志管线；UI 更新仍在 MainActor 上批量合并。

### F. Public API 复核

保留的 PTools 日志入口：

- `PTNSLog` / `PTNSLogConsole`：转发到 `PTLogger`；
- `PTOSLogger`：实现 `PTLogging`，内部调用 `PTLogger`；
- `PTLogFileManager`：保留历史符号，但只转发到 `PTLogger`；
- `PTLogging`、`PTLogEvent`：属于 PToolsCore 的 Foundation-only 值类型契约。

已删除且不应重新引入的旧实现：

- `PTLogSink` / `PTLogSinkCenter` UI sink 兼容实现；
- 影子后端和旧第三方日志依赖。

## 版本收口

| 版本 | 状态 | 结果 |
| --- | --- | --- |
| 5.20.0 | ✅ | 完成日志使用面审计并建立 `PToolsLogging` 基础契约 |
| 5.20.1 | ✅ | 完成 OSLog destination、过滤、缓存和错误摘要 |
| 5.20.2 | ✅ | 完成文件 destination、缓冲、轮转、保留、脱敏和失败降级 |
| 5.21.0 | ✅ | 完成内部日志入口迁移到 `PTLogger` |
| 5.21.1 | ✅ | LocalConsole 与 PTInstruments 接入共享内存目标 |
| 5.21.2 | ✅ | 完成隐私、Network 头脱敏、背压、导出和性能测试 |
| 5.22.0 | ✅ | 移除 SwiftPM、CocoaPods 和锁文件中的旧日志依赖 |
| 5.22.1 | ✅ | 删除旧文件日志独立实现、UI sink 和影子兼容实现，保留 PTLogger-only 兼容包装器 |
| 5.22.2 | ✅ | 完成依赖策略、迁移文档、API/性能/Debug/Core/parity 收口 |

## 迁移结论

PTools 5.22.2 已完成计划内的旧日志依赖和兼容层移除。6.0 不需要再承担日志迁移；后续版本只能在 `PTLogger`、`PTLogDestination` 和类型化 `PTLogRecord` 上继续演进。
