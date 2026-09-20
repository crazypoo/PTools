# Debug 与 PTInstruments 架构

## 1. Product Boundary

Debug 和 PTInstruments 属于 `PooToolsDEBUG`，是可选诊断能力，不进入 Core 默认运行路径。
Core 可以提供通用日志 sink、runtime hook 和事件值类型，但不能认识 `LocalConsole`、Debug
window、Inspector、PTInstrumentRecorder 或 Debug 偏好。

```text
PToolsCore / ptools
        ↓ generic hooks, log sink, value snapshots
PooToolsDEBUG
        ↓ adapters, collectors, UI, recorder
LocalConsole / Inspector / PTInstruments / Example
```

## 2. Dependency Direction

`PooToolsDEBUG` 可以依赖 Core、Network、Share、SearchBar、PDF 和需要的 UI 模块；不存在
`ptools → PooToolsDEBUG` 的反向边。SwiftPM 的 `PToolsCore`、`PToolsUIFoundation` 和
`PToolsPermissionCore` 保持独立，CocoaPods/Xcode 继续遵守 Core source contract。

## 3. PTDebugManager

`PTDebugManager` 只负责插件、Collector 注册和生命周期。`PTDebugConfiguration` 是不可变
`Sendable` 快照；`PTDebugPreferences` 是 `MainActor` UserDefaults 所有者，同时兼容旧 key。
`PTDebugEventCenter` 只传递字符串、数字、枚举和日期等值快照，不传 UIKit、`Any` 或可变系统对象。

## 4. Collector Ownership

| Collector | 职责 | 停止语义 |
| --- | --- | --- |
| `PTConsoleCollector` | stdout / stderr | 最后一个 Debug session 释放后停止 |
| `PTNetworkCollector` | URLSession hook 和网络状态事件 | 关闭请求监控后取消任务 |
| `PTLifecycleCollector` | 启动、生命周期和窗口事件 | owner registry 记录不可逆 hook |
| `PTInspectorCollector` | Inspector 生命周期 | manager 幂等停止 |
| `PTCrashCollector` | 崩溃处理器注册 | signal hook 只注册一次 |
| `PTLeakCollector` | 泄漏检测和事件快照 | 清理 callback、observer 和 Task |
| `PTMockLocationCollector` | 模拟定位兼容 hook | 只在 Debug 偏好启用时启动 |

每个 Collector 只能拥有自己的 Task、observer、sink 和 callback；停止必须幂等，Scene disconnect
不能误停其他 Scene 的 collector。

## 5. Logging Sink

Core 日志通过 `PTLogSinkCenter` 和 `PTLogEvent` 提供通用契约；LocalConsole 作为诊断 sink 接收
脱敏后的字符串快照。日志默认不记录 Authorization、Cookie、Token、完整 URL query、用户输入或
完整响应体。Production Core 不隐式安装 LocalConsole sink。

## 6. Runtime Hook / Swizzle Registry

`PTSwizzleRegistry` 以目标类型、原方法、替换方法、class/instance 标记和 owner 作为唯一键。
重复 start 不重复交换实现。可逆状态（Task、callback、observer、console sink）在 stop 时释放；
Objective-C swizzle 和 signal handler 没有通用安全 undo 时，必须登记不可逆原因和 owner。

新增 hook 先登记 owner，再通过 registry 执行；禁止在业务路径直接裸调用 swizzle。

## 7. Scene / Window Ownership

LocalConsole、Inspector 和 PTInstrument Dashboard 必须绑定发起调用的 `UIWindowScene`。不使用
进程级 key window 作为默认展示目标。多 Scene 各自拥有 console/sink/session 引用，关闭一个 Scene
不会停止其他 Scene 的采集。断开 Scene 时清理 window、root controller、sink、observer 和异步任务。

## 8. Hook Ownership

每个运行时 hook 都必须先登记 owner；重复启动命中同一注册键时不得再次交换实现。

| Owner | Hook |
| --- | --- |
| `debug.window` | Debug window 生命周期 |
| `debug.view-border` | View border |
| `debug.network` | URLSession 配置 |
| `debug.lifecycle` | UIViewController 生命周期 |
| `debug.inspector` | Inspector view hook |
| `debug.mock-location` | CLLocationManager |
| `debug.console-border` | 控制台边框显示 |
| `core.context-menu` | Core 通用 context menu 能力 |
| `core.window-subview` | Core 通用 window subview 能力 |

停止时释放可安全撤销的 Task、callback、notification 和 console sink；Objective-C swizzle 与 signal
handler 若没有安全通用的撤销方式，必须保留 owner 和不可逆原因。

`PTDebugHookRegistry` 是 5.18.0 起的统一可逆入口。Collector 使用 `collector.<identifier>` 注册，
Core runtime adapter 使用 `runtime-adapter` 注册；`install()`、`uninstall()` 和 `isInstalled` 都在
`MainActor` 上执行。Registry 只保存安装/卸载闭包和不可变描述快照，不把 UIKit 对象或动态 `Any`
跨 actor 传递。

## 9. PTInstruments Data Flow

```text
Debug collectors / log sink / display link / resource reader
                         ↓
              PTInstrumentRecorder
                         ↓
                 PTInstrumentSession (actor)
                         ↓
       Timeline / Event Inspector / .pttrace store
```

Session actor 是唯一可变采样状态所有者。Recorder、采样器和 UI 之间只传 `Sendable` 的日期、
数字、字符串、枚举和结构化快照。

## 10. Recorder / Session / Tracks

`PTInstrumentRecorder` 的 start/stop、UI 和日志入口位于 `MainActor`；`PTInstrumentSession` 负责
容量、时长、结束状态和 dropped count。只选择需要的 Instrument 才创建对应采样器：

- FPS、frame time、hitch：单一 `CADisplayLink`，使用活动屏幕刷新率。
- CPU、memory、main-thread stall：可取消的资源/探针 Task。
- Network、lifecycle、leak、logs：复用既有 Debug Collector，不重新 swizzle。
- Custom trace：显式 token、嵌套 parent ID 和重复 end 保护。

未调用 `start` 时不创建 DisplayLink、采样 Task、observer 或 trace store。超过样本、事件、日志、
会话时长和归档大小上限时增加 dropped count，不无限增长内存。

采样能力包括 FPS/frame time/hitch、CPU、memory、disk、threads、main-thread stall、network、
launch、ViewController lifecycle、app/scene lifecycle、tasks、signposts、leak、logs 和 custom trace；
每一种能力只能在宿主显式选择后创建对应采样器。`PTInstrumentTimelineView`、
`PTInstrumentEventInspectorViewController` 和 `PTInstrumentDashboardViewController` 只消费快照，
不直接修改 Session actor。

Session 使用固定容量的环形缓冲保存 samples/events。容量达到策略上限后覆盖最旧记录并增加
`droppedCount`，不会因 30–60 分钟录制持续扩大内存。Dashboard 每 500ms 批量读取一次快照，
不会按每条采样刷新 UIKit。

## 11. Timeline / Inspector

Timeline 使用有界 snapshot 渲染轨道、时间范围、缩放、过滤和选中状态，不维护第二份采集状态。
Inspector 根据事件时间和 track 关联附近样本；UI 只读取 snapshot，不直接修改 Session actor 状态。

## 12. Export / Import

`.pttrace` 是 JSON 归档，保存前和导入后都执行 redaction。导出不包含完整 URL query、fragment、
Authorization、Cookie、Token、密码、响应正文或用户输入。`importTrace` 会先检查归档大小；`replay`
只生成过滤后的值类型时间线，不执行归档中的业务代码；`compare` 只返回持续时间、事件、样本和
丢弃数量差异。导出、导入、回放、对比和删除由宿主 Debug UI 显式触发。

## 13. Privacy / Redaction

脱敏分两层：事件进入 Session 前处理一次，`PTInstrumentTraceStore.save` 再处理一次。metadata key
包含 `authorization`、`cookie`、`token`、`password`、`secret`、`credential` 或 `body` 时写入
`[REDACTED]`。网络 body 默认关闭；开启高成本采样必须有测试环境 Debug 开关和明确分享范围。

Session metadata 只包含 bundle、版本、系统、设备型号和屏幕刷新率等诊断所需信息，不采集用户
输入、完整业务响应或完整 URL 参数。开启长时间录制、网络 body、更多日志保留量或更高采样频率
前，宿主必须显式展示 Debug 开关并控制归档分享范围。

Signal handler、NSException handler 和崩溃退出路径不得调用 Swift actor、UI、文件导出或 sink callback。

## 14. Disabled-State Contract

Debug disabled 或 recorder stopped 时：

- 不创建 Debug window、DisplayLink、采样 Task、PTInstrument session 或高频 observer。
- Core 日志可以使用基础 sink，但不能反向依赖 LocalConsole 或 PTInstruments。
- production build 不因为诊断模块存在而改变业务窗口、网络和媒体行为。

## 15. Performance Contract

必须在同一设备、同一构建和同一脚本下比较 Core only、Debug hidden、单 Scene recording、双 Scene
recording 四种状态。至少重复五次，记录中位数和峰值。Simulator 只证明功能和构建，不作为真实
CPU、内存、FPS 或发布性能预算。

## 16. Deferred Capabilities

5.x 不实现完整 Time Profiler call tree、Allocations object graph、System/Metal Trace、Mach stack
unwinding、符号化和 dSYM profiler pipeline。它们应作为独立高风险项目，不得隐式进入基础诊断路径。
