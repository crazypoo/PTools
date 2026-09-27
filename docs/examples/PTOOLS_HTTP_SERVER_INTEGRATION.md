# PTools HTTP Server 集成示例

## Debug 文件门户

```swift
let configuration = PTHTTPFilePortalConfiguration(
    rootDirectory: URL(fileURLWithPath: PTUploadFilePath),
    allowedFileExtensions: ["jpg", "png", "mov", "mp4", "pdf"]
)
let portal = PTHTTPFilePortal(configuration: configuration)
let endpoint = try await portal.start()
```

将 `endpoint.bonjourName` 和可用 URL 展示给调试 UI；页面只允许访问配置的 root directory。
页面关闭或 Scene 离开时调用 `await portal.stop()`，不要把 actor 服务绑定到 `MainActor`。

## API 与 SSE

```swift
let server = PTHTTPServer()
await server.use(PTHTTPCompressionMiddleware())
await server.get("/api/status") { _ in
    try .json(StatusSnapshot(isReady: true))
}
await server.sse("/api/live") { _ in
    let stream = PTHTTPSSEStream()
    stream.send(.init(data: "ready", event: "status"))
    return stream
}
```

调试数据应先在宿主侧聚合/降频，再通过 SSE 推送；PTools HTTP 层不理解业务 telemetry、车辆协议或用户数据。

