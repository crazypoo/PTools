# SocketRocket 到原生 WebSocket 迁移指南

## 迁移原则

5.27.0 使用 iOS 17+ 的 `URLSessionWebSocketTask`。新代码优先使用
`PTWebSocketClient`；已有代码可以继续使用 `PTSocketManager.share`，不需要一次性改完。

## 新入口

```swift
let configuration = PTWebSocketConfiguration(
    url: URL(string: "wss://example.com/socket")!,
    heartbeat: .init(interval: .seconds(30), timeout: .seconds(10)),
    trustPolicy: .systemDefault
)

let client = PTWebSocketClient(configuration: configuration)
try await client.connect()
try await client.send(.text("hello"))

for await event in client.events {
    switch event {
    case .message(let message):
        // English: Business code handles value-type messages only.
        // Español: El código de negocio solo procesa mensajes de tipos de valor.
        // 中文：业务代码只处理值类型消息。
        _ = message
    default:
        break
    }
}
```

## 兼容入口

`PTSocketManager` 的以下入口继续可用：

- `socketSet(completion:)`
- `connect()`、`disConnect(clearQueue:)`、`reConnect()`
- `sendMessage(_:)`
- `addDelegate(_:)`、`removeDelegate(_:)`
- `nWebSocketDidConnect`、`nWebSocketDidDisconnect` 和消息通知

兼容入口只接受 `String` 或 `Data`。不支持的动态消息会被安全忽略，不再进入原生
并发核心。

## 安全配置

默认使用系统 TLS 信任链。需要 pinning 时使用
`PTWebSocketTrustPolicy.pinnedCertificates` 或 `.pinnedPublicKeys`，生产代码不得
添加绕过信任的策略。

## 行为变化

- `connect()` 在 URLSession 委托确认打开后才进入 `.connected`。
- 未连接时消息进入有界 FIFO 缓冲；满载时默认拒绝最新消息。
- 重连由单一任务负责，采用指数退避和抖动；稳定连接后重置重连预算。
- 日志默认记录事件类型、错误和字节数，不记录完整消息体、Token 或 Cookie。
