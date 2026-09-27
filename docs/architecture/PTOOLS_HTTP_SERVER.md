# PTools 原生 HTTP Server 架构

## 分层

```text
PToolsHTTPFilePortal
        ↓
PToolsHTTPServer
        ↓
Network.framework / NWListener / NWConnection
```

`PTHTTPServer` 是 actor，负责监听器、路由快照、中间件、连接注册、指标和优雅停止。
每条连接由独立的 `PTHTTPConnection` actor 管理读取、HTTP parser、Keep-Alive 和响应写入。
Network.framework 的引用只被窄范围 transport wrapper 持有；请求、响应、header、body descriptor、
路由参数和错误均为 Swift 6 `Sendable` 值类型。

## 能力矩阵

| 能力 | 5.28.0 实现 |
| --- | --- |
| HTTP/1.1 request line/header | 增量解析，大小、数量和 framing 限制 |
| Body | Content-Length、chunked、1 MiB 后临时文件 |
| Router | exact > parameter > wildcard，priority > registration order |
| 生命周期 | async start、graceful stop、force stop、idle timeout、连接上限 |
| Response | text、JSON、Data、文件、chunked stream、SSE |
| 静态资源 | MIME、HEAD、Range、ETag、Last-Modified、304、symlink policy |
| Middleware | Host、CORS、Bearer、rate limit、gzip |
| Discovery/Security | Bonjour service、loopback/local network、可选 TLS、token |
| File Portal | listing、upload、download、delete、mkdir、rename（均由开关控制） |

## 有意不实现

5.28.0 不提供 HTTP/2、HTTP/3、WebDAV、反向代理、多 Range multipart response 或任意路径浏览。
这些功能不属于 PTools 的本地调试/文件分享边界，避免把轻量基础设施再次膨胀成通用网关。

## 调用示例

```swift
let server = PTHTTPServer(configuration: .init(bindScope: .loopback))
await server.get("/health") { _ in
    .text("ok")
}
let endpoint = try await server.start()
defer { Task { await server.stop() } }
print(endpoint.urls)
```

