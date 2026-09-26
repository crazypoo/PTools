# PTools WebSocket 架构

## 分层

```text
PTSocketManager（MainActor 兼容门面）
        ↓ 值类型事件
PTWebSocketClient（actor 核心）
        ↓ transport 协议
PTURLSessionWebSocketTransport（URLSession actor）
        ↓ 委托回调
URLSessionWebSocketTask
```

`PTWebSocketClient` 持有状态、代际令牌、缓冲、重连、心跳和指标。系统委托回调只
通过一个窄范围 `@unchecked Sendable` proxy 进入 actor，并且只发送不可变事件快照。

## 生命周期

1. `connect()` 创建新 generation，并等待 `didOpen` 后发布 `.connected`。
2. 所有传输事件携带 generation；旧连接的延迟回调会被丢弃。
3. close/fail/heartbeat timeout 只允许当前 generation 终结一次。
4. 非手动失败才会创建一个重连任务；手动断开会取消重连和心跳。
5. 连接稳定达到阈值后重置重连计数。

## 数据与日志

消息只使用 `String` / `Data` 两种 `Sendable` 值。日志只输出消息类型、字节数、状态
和类型化错误；敏感头与完整 payload 不进入默认日志。

## TLS 信任

系统默认信任使用系统处理。证书 pinning 和公钥 pinning 在系统信任成功后再比较 pin，
失败直接取消 challenge。代码库不提供 `allowAll` 或类似的生产绕过开关。
