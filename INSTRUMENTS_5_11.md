# PTools 5.11.x PTInstruments

## 范围

`PTInstruments` 属于 `PooToolsDEBUG`，只在显式调用 `PTInstrumentRecorder` 后工作。它消费
5.10.x 已有的 `PTDebugEventCenter`、`PTLogSinkCenter` 和 Debug Collector，不向 Core、Network
或业务模块反向添加调试依赖，也不重复安装 URLSession、生命周期或泄漏检测 swizzle。

数据链路如下：

```text
Debug Collectors / Core Log Sink / display link / resource reader
                         ↓
              PTInstrumentRecorder
                         ↓
                 PTInstrumentSession
                         ↓
             Timeline / Inspector / .pttrace
```

## 已提供能力

| 能力 | 实现 | 说明 |
| --- | --- | --- |
| Session / Track | `PTInstrumentSession`、`PTInstrumentTrack` | actor 单独持有可变采样状态、数量限制和结束时间 |
| FPS / Frame Time | `PTInstrumentDisplayLinkSampler` | 使用活动屏幕真实刷新率；hitch 按实际 frame budget 判断 |
| CPU / Memory | `PTInstrumentResourceSampler` | 读取进程快照，按策略周期采样 |
| Main Thread Stall | `PTMainThreadStallSampler` | 可取消的 MainActor 空操作探针，不阻塞业务线程 |
| Network | `PTInstrumentNetworkRecord`、已有 Debug Network event | URL、请求方法和错误信息在跨边界前以字符串摘要传递 |
| Lifecycle / Leak | `PTDebugEventCenter` | 复用已有 Collector；VC 生命周期只发布不可变名称快照 |
| Logs | `PTLogSinkCenter` | 复用 Core 日志 sink，记录 level、category 和脱敏文本 |
| Crash marker | `recordCrashMarker` | 仅供业务在安全上下文显式记录；不在 Unix signal handler 中调用 |
| Timeline | `PTInstrumentTimelineView` | 横向滚动、缩放、轨道显示、文本过滤、时间范围和事件选中 |
| Inspector | `PTInstrumentEventInspectorViewController` | 展示事件并关联附近 Track 的事件和样本 |
| Export / Import | `PTInstrumentTraceStore` | `.pttrace` JSON 归档、历史记录、导入和导出前再次脱敏 |
| Custom Trace | `PTTrace` | 同步/异步测量、显式 token、嵌套 parent ID、重复 end 保护 |

## 最小使用示例

```swift
@MainActor
func startDiagnostics(in window: UIWindow?) {
    let policy = PTInstrumentSamplingPolicy(
        cpuMemoryInterval: 1,
        fpsSampleInterval: 0.25,
        maxSessionDuration: 120,
        captureNetworkBodies: false
    )
    let session = PTInstrumentRecorder.shared.start(
        instruments: [.fps, .frameTime, .hitch, .cpu, .memory,
                      .mainThreadStall, .network, .lifecycle, .logs, .leak],
        policy: policy,
        window: window
    )

    let trace = PTTrace.begin("Image Decode", session: session)
    // 执行业务操作后结束 token；结束操作本身是幂等的。
    trace.end()
}

@MainActor
func stopDiagnostics() {
    Task { @MainActor in
        guard let snapshot = await PTInstrumentRecorder.shared.stop() else { return }
        let url = try? PTInstrumentTraceStore.save(snapshot)
        print("trace: \(url?.path ?? "-")")
    }
}
```

异步业务可以直接使用：

```swift
let value = try await PTTrace.measure("Load User") {
    try await loadUser()
}
```

`PTInstrumentRecorder` 的 start/stop、日志和 UI 入口位于 `MainActor`；Session 本身是 actor，
采样器只能向它发送 `Sendable` 的日期、数字、字符串和枚举值。调用方需要显式停止录制，或
依靠 `maxSessionDuration` 的自动终止；停止后不再接受样本和事件。

## 采样与边界

- 未调用 `start` 时不创建 DisplayLink、采样 Task 或 Debug event/log observer。
- 只选择需要的 Instrument，未选择的 Track 不采样。
- Session 对样本、事件、日志保留量、总时长和 `.pttrace` 大小设有上限。
- 大量长会话通过上限控制内存；时间线渲染消费有界 snapshot，不维护第二份采集状态。
- `captureNetworkBodies` 目前默认关闭，导出仍会对 URL、metadata 和文本执行二次脱敏。
- Crash signal / NSException 处理器不得调用 Swift 并发或 UI 代码；`recordCrashMarker` 只适用于
  正常运行上下文中的业务标记。

## 明确延期

本版本不实现完整 Time Profiler call tree、Allocations object graph、System/Metal Trace、Mach
stack unwinding、符号化和 dSYM profiler pipeline。这些能力会显著扩大运行时风险，不应成为
5.x Debug 诊断基础的隐式依赖。

## 验证边界

静态门禁、SwiftPM manifest、差异检查和 PooTools-Example Simulator Debug/Release 构建只能
证明源码和构建契约；真机耗时、CPU、内存、帧率、长会话以及真实宿主回归必须按
`INSTRUMENTS_OVERHEAD_BASELINE_5_11.md` 单独执行。
