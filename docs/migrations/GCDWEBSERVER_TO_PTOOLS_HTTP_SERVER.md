# GCDWebServer 到 PToolsHTTPServer 迁移

## 入口映射

| 旧入口 | 新入口 |
| --- | --- |
| `GCDWebServer` | `PTHTTPServer` |
| `GCDWebServerRequest` | `PTHTTPRequest` |
| `GCDWebServerResponse` | `PTHTTPResponse` |
| `GCDWebUploader` | `PTHTTPFilePortal` |
| `GCDWebServer/WebUploader` subspec | `PooTools/HTTPFilePortal` |

## Server

```swift
let server = PTHTTPServer(configuration: .init(bindScope: .loopback))
await server.get("/health") { _ in
    .text("ok")
}
let endpoint = try await server.start()
// 使用完成后：await server.stop()
```

Handler 统一为 `@Sendable (PTHTTPRequest) async throws -> PTHTTPResponse`，不再维护同步 block、
异步 completion 和 response subclass 三套核心入口。`PTHTTPResponse.json` 只接受 `Encodable & Sendable`。

## File Portal

```swift
let portal = PTHTTPFilePortal(
    configuration: .init(
        rootDirectory: documentsDirectory,
        allowsUpload: true,
        allowsDownload: true,
        allowsDelete: false
    )
)
let endpoint = try await portal.start()
```

旧的 `GCDWebUploaderDelegate` 回调不再适配；状态通过 `PTHTTPServerMetrics`、宿主 UI 或自己的 SSE/API 路由提供。

## 迁移注意事项

1. `PooTools/GCDWebServer` 可以短期继续安装，但它只是转发 alias，不再提供第三方模块。
2. 不要在业务代码中声明或保存 `GCDWebServer*` 类型；使用 `PTHTTPRequest`/`PTHTTPResponse` 值类型。
3. File Portal 默认不允许删除、mkdir 和 rename，需要在配置中显式开启。
4. 局域网服务必须使用 `.localNetwork` 并配置本地网络权限说明；loopback 不需要暴露到局域网。
5. 旧 WebUploader 的页面定制不保证 source-compatible；PTools 提供离线 vanilla HTML 入口，复杂 UI 可直接调用 REST API。

