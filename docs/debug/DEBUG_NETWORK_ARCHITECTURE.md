# DebugNetwork 2.0 架构

## 单向数据流

```text
URLProtocol / PTools Network adapter
        ↓ immutable event
PTNetworkCaptureStore (actor)
        ↓ summary / record(id:)
Scene-scoped watcher UI
        ↓ redacted by default
cURL / HAR / Text / Share
```

Capture 层只做转发、采样、指标和记录；业务 Network 继续独立负责 cache、retry、auth、dedup、validation 和 decoder。

## 状态与生命周期

记录状态为 `created → requestStarted → responseReceived → receivingBody → finalized`。Store 对同一 UUID 只允许一次 finalize；取消、错误、成功、重定向和缓存命中都必须进入终态。

全局 Capture Engine 与 Scene presentation 分离。每个 Scene 的搜索、过滤、选中项和浮层由 `PTNetworkDebugPresentationSession` 独立持有；界面退出只释放自身 Task、Timer 和观察流，不停止其他 Scene 的抓包。

## 兼容层

`PTHttpModel`、`PTHttpDatasource` 和 `PTNetworkHelper` 暂时保留给 5.x 旧 UI。它们只把 immutable record 投影到旧展示模型，不再作为抓包事实源。新代码应直接使用 `PTNetworkCaptureRecord`、`PTNetworkCaptureStore` 和 `PTNetworkExportManager`。

## Hook 治理

`URLSessionConfiguration` 的不可逆 runtime hook 只登记一次，登记信息包含 owner、kind、activation 和 hook ID。通过 `PTDebugHookRegistryStore` 可审计安装状态，避免多个调试模块重复 swizzle。
