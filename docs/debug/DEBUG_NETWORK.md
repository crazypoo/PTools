# DebugNetwork 2.0

DebugNetwork 是只读的网络观测工具。它只观察请求、响应、指标和错误，不参与业务缓存、重试、鉴权、去重、解码或响应决策。

## 启用与关闭

网络抓包开关由现有 `PTNetworkHelper` / LocalConsole 控制。开启后，`URLProtocol` 只转发原始请求，关闭后业务请求继续由原来的 `URLSession` 或 Network 入口执行。

```swift
@MainActor
func setDebugNetwork(_ enabled: Bool) {
    if enabled {
        PTNetworkHelper.shared.enable()
    } else {
        PTNetworkHelper.shared.disable()
    }
}
```

PTools Network 的业务路径可以通过只读适配器提交 `PTNetworkCaptureRecord`；适配器不能修改请求或响应。

## 能力

- `PTNetworkCaptureRecord`：不可变、`Sendable`、`Codable` 的请求记录。
- `PTNetworkCaptureStore`：actor 负责顺序号、并发访问、正文预算、磁盘预算和 exactly-once finalize。
- `URLSessionTaskMetrics`：DNS、TCP、TLS、Upload、TTFB、Download 和重定向指标。
- `PTNetworkCaptureFilter`：URL、Host、Method、Status、失败、耗时、大小、缓存来源和关键词过滤。
- `PTNetworkCurlExporter`、`PTNetworkHARExporter`、`PTNetworkTextExporter`：默认脱敏后复制或导出。
- `AsyncStream<PTNetworkCaptureChange>`：UI 以 100–200ms 批量合并更新，不按请求全量刷新。

## 正文限制

默认策略：预览 512 KB、文件阈值 2 MB、单正文绝对上限 50 MB、Store 内存预算 64 MB、临时文件预算 256 MB。`httpBodyStream` 不会被无上限读取，只记录未知大小的有界标记。

## 验收边界

需要真机/真实宿主确认的内容包括后台 URLSession、WKWebView、WebSocket、SSE、Network.framework 和弱网行为；静态检查不能替代这些验证。

详细设计见：

- [架构](DEBUG_NETWORK_ARCHITECTURE.md)
- [能力矩阵](DEBUG_NETWORK_CAPABILITY_MATRIX.md)
- [隐私与导出](DEBUG_NETWORK_PRIVACY.md)
- [6.0 迁移](DEBUG_NETWORK_MIGRATION_6.md)
- [Example fixture](DEBUG_NETWORK_EXAMPLE.md)
