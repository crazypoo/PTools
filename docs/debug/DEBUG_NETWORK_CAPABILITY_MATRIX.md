# DebugNetwork 能力矩阵

| 传输/入口 | 状态 | 说明 |
| --- | --- | --- |
| `URLSession.shared` | SUPPORTED | 通过 URLProtocol fallback 观察 HTTP/HTTPS 请求。 |
| default configuration | SUPPORTED | 被 runtime hook 后注入观察协议。 |
| ephemeral configuration | SUPPORTED | 使用无业务缓存的转发 session。 |
| custom configuration | LIMITED | 取决于是否允许 URLProtocol 和宿主自定义 delegate。 |
| async URLSession | SUPPORTED | 仍由 URLProtocol/底层 URL Loading System 观察。 |
| uploadTask | LIMITED | 请求正文可观察；大 body 和 stream 按 capture policy 限制。 |
| downloadTask | LIMITED | 需要宿主补充文件落盘与进度验证。 |
| `httpBodyStream` | LIMITED | 不消费 stream，不承诺完整正文。 |
| background URLSession | NOT_SUPPORTED | 需要独立的宿主 delegate 生命周期和进程外回调验证。 |
| Alamofire | SUPPORTED | 仅在底层使用 URLSession 时通过 fallback 观察；业务事件可用只读 adapter 补充。 |
| WebSocket | NOT_SUPPORTED | 不伪造 HTTP capture；使用 SocketKit 自己的诊断事件。 |
| SSE | LIMITED | HTTP 响应可观察，长连接终态和分段 UI 需宿主验证。 |
| WKWebView | NOT_SUPPORTED | WebKit 网络进程不保证经过应用 URLProtocol。 |
| Network.framework | NOT_SUPPORTED | 不属于 URL Loading System；由对应模块提供独立指标。 |

状态含义：`SUPPORTED` 表示契约稳定，`LIMITED` 表示有明确边界，`NOT_SUPPORTED` 表示不伪造能力且不改变业务行为。
