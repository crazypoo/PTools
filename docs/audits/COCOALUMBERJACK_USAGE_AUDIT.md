# CocoaLumberjack 使用审计

本报告对应 5.21.2，基于当前工作区的 `VERSION` 和源码快照生成。它记录 5.20.x 基础层和
5.21.x 内部调用迁移的事实结果，不等于删除 CocoaLumberjack。依赖删除和兼容层清理属于
后续 5.22.x 里程碑。

## 审计范围与命令

扫描覆盖仓库源码、SwiftPM、CocoaPods、锁文件和架构文档；排除 Git 元数据、已安装 Pods 和
生成的历史报告，避免把第三方源码副本当成 PTools 自有调用。

```bash
rg "CocoaLumberjack" . --hidden --glob '!.git/**' --glob '!Pods/**' --glob '!report/**'
rg "CocoaLumberjackSwift" . --hidden --glob '!.git/**' --glob '!Pods/**' --glob '!report/**'
rg "DDLog|DDFileLogger|DDOSLogger|DDLogger|DDLogMessage|DDLogLevel|dynamicLogLevel" \
  . --hidden --glob '!.git/**' --glob '!Pods/**' --glob '!report/**'
rg "PTLog|PTNSLog|PTDebugLog|PToolsLog|LogManager|LoggerManager" \
  PooToolsSource docs Package.swift PooTools.podspec
```

审计结果：

- ✅ 依赖声明已定位：`Package.swift`、`Package.resolved`、`PooTools.podspec` 和 `Podfile.lock`。
- ✅ 旧日志兼容入口已定位：`PooToolsSource/Log/PTNSLog.swift`；当前没有直接 CocoaLumberjack 导入。
- ✅ `DDFileLogger`、`DDLogger`、`DDLogLevel` 和 `dynamicLogLevel` 未发现。
- ✅ 没有发现公开 API 直接暴露 `DD*` 类型。
- ✅ 自定义 formatter 未使用 `DDLogFormatter`；当前格式化逻辑在 `PTNSLog` 内生成字符串。
- ✅ 运行时日志等级由 `LoggerEXLevelType`、`PTLogMode` 和生产/TestFlight 判断组成，未使用
  `dynamicLogLevel` 或 `DDLogLevel`。

## 结果分类

### A. 纯日志调用

5.21.0 已完成内部调用迁移：`PooToolsSource/Log/PTNSLog.swift` 现在把日志记录转换为
不可变 `PTLogRecord` 并交给 `PTLogger`；生产 Swift 中没有 `DDLog*` 或
`import CocoaLumberjack`。Core 和 Debug 的业务调用仍可使用公开兼容入口
`PTNSLog` / `PTNSLogConsole`，但它们不再把 CocoaLumberjack 类型带入新的执行路径。

### B. File Logger

未发现 `DDFileLogger`。现有文件日志实现是 `PooToolsSource/Log/PTLogFileManager.swift`：

- `actor` 串行追加到 Caches 目录的 `log.txt`；
- 单文件达到 5 MiB 时滚动为 `log.1.log`；
- 旧文件同名覆盖，当前没有 CocoaLumberjack 的多文件 retention 配置；
- `PTNSLog` 通过 `isWriteLog` 决定是否异步写入；
- LocalConsole / PTInstruments 消费的是 `PTLogEvent` / `PTLogSinkCenter`，不是 DDFileLogger 文件读取。

5.20.2 新增的 `PTFileLogDestination` 已使用独立目录、32 KB 缓冲、单消费者流、flush、
rotation、retention 和隐私脱敏；旧 `PTLogFileManager` 仍保留给兼容入口，不在本轮删除。

### C. Formatter

未发现 `DDLogFormatter` 或 `format(message:)` 实现。`PTNSLog` 仍保留旧的多行文本格式，新的
`PTLogRecord` 同时保存时间、文件、行列、函数、分类和元数据。兼容输出不因 5.21.x 迁移改变，
持久化目标统一在写入前执行脱敏。

### D. Runtime Level

当前运行时等级入口：

- `LoggerEXLevelType`：旧公开等级枚举；
- `PTLogMode`：根据 Debug、TestFlight 和 App Store 环境选择等级；
- `PTNSLog`：将旧等级映射到 `PTLogSeverity` 和 `PTLogger`，再由兼容 sink 提供旧 UI 消费。

没有 `DDLogLevel` 或 `dynamicLogLevel` 的动态全局变量。新 `PToolsLogging` 在 5.21.x 提供
`PTLogLevel`、按 category 的最低等级、subsystem 配置、默认 OSLog destination、内存 destination、
背压策略和隐私脱敏；`PTNSLog` 已通过兼容桥接接管。

### E. Custom Logger

未发现 `DDLogger` 或 `DDAbstractLogger` 自定义实现。现有 `PTOSLogger`、`PTLogSink`、
`PTLogSinkCenter` 和 `PTLogFileManager` 是 PTools 自有包装，继续作为旧兼容层保留。

### F. Public API 泄露

未发现 `public` 属性、参数或返回值使用 `DDLogger`、`DDFileLogger`、`DDLogMessage`、
`DDLogLevel` 等 CocoaLumberjack 类型。公开 API 中可见的是 `PTNSLog`、`PTNSLogConsole`、
`PTLogFileManager`、`PTOSLogger`、`PTLogging` 和 `PTLogEvent`。

## 5.20.x / 5.21.x 基础架构落点

新增 `PToolsLogging`，仅包含 Foundation 值类型和日志门面：

- `PTLogLevel`：可比较、可跨 actor 传递的等级；
- `PTLogCategory`：稳定字符串分类；
- `PTLogRecord`：不可变日志快照；
- `PTLogConfiguration`：全局最低等级、分类等级和 subsystem；
- `PTLogDestination`：后端扩展契约；
- `PTLogger`：惰性同步写入、过滤、序列号、默认 OSLog 输出、文件目标安装和异步 flush 入口。
- `PTOSLogDestination`：按 subsystem/category 缓存 Apple `Logger`，并根据隐私级别映射 OSLog privacy。
- `PTFileLogDestination`：可选文件后端，使用 `Library/Caches/PTools/Logs`、32 KB buffer、异步 flush、
  5 MiB/24 小时轮转和 7 天/7 文件/30 MiB 清理策略。
- `PTLogRedactor`：对 Authorization、Cookie、token、password、secret 等 key 做大小写不敏感脱敏。
- `PTMemoryLogDestination`：使用 actor 所有的有界 Ring Buffer、单 worker、背压计数和多订阅流，供 LocalConsole 与 PTInstruments 复用。
- `PTLogger.exportLogFiles`：在返回持久化文件前刷新文件目标，避免导出时遗漏缓冲记录。

SwiftPM product 为 `PToolsLogging`，CocoaPods subspec 为 `PooTools/Logging`。Core 依赖新契约，
旧 `PooToolsSource/Log`、CocoaLumberjack 依赖和公开兼容入口均未删除，避免 5.x 引入破坏性迁移。

## 后续迁移边界

| 版本 | 允许的变化 |
| --- | --- |
| 5.20.1 | ✅ OSLog destination、缓存、运行时等级过滤、Error 摘要和基础测试；旧 CocoaLumberjack 仍存在 |
| 5.20.2 | ✅ 文件 destination、flush、rotation、retention、脱敏、容量边界和失败兜底 |
| 5.21.0 | ✅ 内部 `DDLog*` 实现迁移到 `PTLogger`，旧 `PTNSLog*` 入口转为兼容包装器 |
| 5.21.1 | ✅ LocalConsole、PTInstruments、Ring Buffer 和 UI batching 接入共享内存目标 |
| 5.21.2 | ✅ 隐私 API、Network 头脱敏、背压、drop policy、后台 flush、导出和性能测试 |
| 5.22.0+ | 只有迁移证据、API 对照和三套构建通过后，才删除 CocoaLumberjack |

本报告的结论是“已完成使用面审计并建立新契约”，不代表 CocoaLumberjack 已移除。
