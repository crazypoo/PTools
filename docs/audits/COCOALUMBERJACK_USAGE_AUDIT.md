# CocoaLumberjack 使用审计

本报告对应 5.20.0，基于当前工作区的 `VERSION` 和源码快照生成。它是迁移前的事实清单，
不是删除 CocoaLumberjack 的变更请求。5.20.0 只建立日志基础契约；依赖删除、旧调用迁移和
兼容层清理分别属于后续 5.21.x / 5.22.x 里程碑。

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
- ✅ 直接源码导入已定位：`PooToolsSource/Log/PTNSLog.swift`。
- ✅ `DDFileLogger`、`DDLogger`、`DDLogLevel` 和 `dynamicLogLevel` 未发现。
- ✅ 没有发现公开 API 直接暴露 `DD*` 类型。
- ✅ 自定义 formatter 未使用 `DDLogFormatter`；当前格式化逻辑在 `PTNSLog` 内生成字符串。
- ✅ 运行时日志等级由 `LoggerEXLevelType`、`PTLogMode` 和生产/TestFlight 判断组成，未使用
  `dynamicLogLevel` 或 `DDLogLevel`。

## 结果分类

### A. 纯日志调用

`PooToolsSource/Log/PTNSLog.swift` 中的 `DDLogDebug`、`DDLogInfo`、`DDLogWarn`、
`DDLogError` 和 `DDLogVerbose` 由私有 `DDLogSet` 统一调用。生产环境路径通过
`DDOSLogger.sharedInstance` 写入 CocoaLumberjack；其他环境使用现有 `OSLog.Logger` 路径。

Core 和 Debug 的业务调用主要通过公开兼容入口 `PTNSLog` / `PTNSLogConsole`，没有在其他文件
直接调用 `DDLog*`。这些调用保留到 5.21.0 的分模块迁移阶段。

### B. File Logger

未发现 `DDFileLogger`。现有文件日志实现是 `PooToolsSource/Log/PTLogFileManager.swift`：

- `actor` 串行追加到 Caches 目录的 `log.txt`；
- 单文件达到 5 MiB 时滚动为 `log.1.log`；
- 旧文件同名覆盖，当前没有 CocoaLumberjack 的多文件 retention 配置；
- `PTNSLog` 通过 `isWriteLog` 决定是否异步写入；
- LocalConsole / PTInstruments 消费的是 `PTLogEvent` / `PTLogSinkCenter`，不是 DDFileLogger 文件读取。

该实现的统一 `PTFileLogDestination`、buffer、flush、rotation 和 retention 属于 5.20.2。

### C. Formatter

未发现 `DDLogFormatter` 或 `format(message:)` 实现。`PTNSLog` 当前自行生成包含环境、时间、
文件、行列、函数和消息正文的多行字符串。格式字段需要在 5.20.2 的文件后端设计中保持兼容，
不能在 5.20.0 直接改变旧日志输出。

### D. Runtime Level

当前运行时等级入口：

- `LoggerEXLevelType`：旧公开等级枚举；
- `PTLogMode`：根据 Debug、TestFlight 和 App Store 环境选择等级；
- `PTNSLog`：将旧等级映射到 `PTLogSeverity` 和旧 OSLog/CocoaLumberjack 输出。

没有 `DDLogLevel` 或 `dynamicLogLevel` 的动态全局变量。新 `PToolsLogging` 在 5.20.0 提供
`PTLogLevel`、按 category 的最低等级和 subsystem 配置，但尚未接管旧 PTNSLog 输出。

### E. Custom Logger

未发现 `DDLogger` 或 `DDAbstractLogger` 自定义实现。现有 `PTOSLogger`、`PTLogSink`、
`PTLogSinkCenter` 和 `PTLogFileManager` 是 PTools 自有包装，继续作为旧兼容层保留。

### F. Public API 泄露

未发现 `public` 属性、参数或返回值使用 `DDLogger`、`DDFileLogger`、`DDLogMessage`、
`DDLogLevel` 等 CocoaLumberjack 类型。公开 API 中可见的是 `PTNSLog`、`PTNSLogConsole`、
`PTLogFileManager`、`PTOSLogger`、`PTLogging` 和 `PTLogEvent`。

## 5.20.0 基础架构落点

新增 `PToolsLogging`，仅包含 Foundation 值类型和日志门面：

- `PTLogLevel`：可比较、可跨 actor 传递的等级；
- `PTLogCategory`：稳定字符串分类；
- `PTLogRecord`：不可变日志快照；
- `PTLogConfiguration`：全局最低等级、分类等级和 subsystem；
- `PTLogDestination`：后端扩展契约；
- `PTLogger`：惰性同步写入、过滤、序列号和异步 flush 入口。

SwiftPM product 为 `PToolsLogging`，CocoaPods subspec 为 `PooTools/Logging`。Core 依赖新契约，
但旧 `PooToolsSource/Log`、CocoaLumberjack 依赖和公开兼容入口均未删除，避免 5.20.0 引入破坏性
迁移。

## 后续迁移边界

| 版本 | 允许的变化 |
| --- | --- |
| 5.20.1 | 增加 OSLog destination、缓存和基础测试；旧 CocoaLumberjack 仍存在 |
| 5.20.2 | 增加文件 destination、flush、rotation、retention 和失败兜底 |
| 5.21.0 | 按模块把 `DDLog*` / `PTNSLog*` 调用迁移到 `PTLogger` |
| 5.21.1–5.21.2 | LocalConsole、PTInstruments、脱敏和性能接入 |
| 5.22.0+ | 只有迁移证据、API 对照和三套构建通过后，才删除 CocoaLumberjack |

本报告的结论是“已完成使用面审计并建立新契约”，不代表 CocoaLumberjack 已移除。
