# SocketRocket 使用审计

版本：5.27.0  
范围：PooTools `SocketKit`、SwiftPM、CocoaPods、锁文件和测试。

## 结论

5.27.0 已从交付路径移除 SocketRocket。`PTWebSocketClient` 使用系统
`URLSessionWebSocketTask`，`PTSocketManager` 仅保留旧 API 的兼容门面，不再暴露
`SRWebSocket`、`SRWebSocketDelegate` 或 SocketRocket 的任何类型。

## 迁移前后

| 路径 | 5.26.x | 5.27.0 | 处理 |
| --- | --- | --- | --- |
| SwiftPM | SocketRocket revision | Foundation URLSession | 已移除依赖 |
| CocoaPods SocketKit | `SocketRocket` pod | `PooTools/Logging` | 已收口依赖 |
| 连接核心 | `SRWebSocket` | `PTURLSessionWebSocketTransport` | actor 隔离 |
| 旧入口 | `PTSocketManager` 直接持有 SR 对象 | 兼容代理 | 保留源码兼容 |

## 允许的历史记录

`report/baselines` 中的历史 API、架构和供应链报告可以继续出现 SocketRocket 名称，
它们用于记录旧版本事实，不参与当前交付源码、Manifest 或 lockfile 门禁。

## 当前门禁

- `Package.swift`、`PooTools.podspec`、`Package.resolved` 和 `Podfile.lock` 不得包含 SocketRocket。
- `PooToolsSource` 和 `Tests` 不得包含 SocketRocket、`SRWebSocket` 或 `SRReadyState`。
- 原生 WebSocket 不得提供 trust-all 绕过校验。
- 兼容门面只能转换 `String` 与 `Data`，动态 `Any` 不得穿过 actor 核心。
