# WebSocket 测试矩阵

| 领域 | 场景 | 预期 |
| --- | --- | --- |
| 配置 | 非 `ws`/`wss` URL | 返回 `invalidURL`，不崩溃 |
| 状态 | open 前后状态变化 | 委托确认打开后才是 `connected` |
| 代际 | 旧连接延迟 close/fail | 不改变新连接状态 |
| 终结 | close 与 fail 同时到达 | 只发布一次终结事件 |
| 缓冲 | FIFO、容量满、dropOldest | 顺序稳定，策略明确 |
| 重连 | 多次失败、抖动、稳定后恢复 | 单 flight、上限生效、稳定后计数归零 |
| 心跳 | ping 成功、超时、取消 | 发布 pong 或触发失败/重连 |
| TLS | 系统信任、证书 pin、公钥 pin、错误 pin | 成功或取消 challenge，不允许 trust-all |
| 兼容 | `PTSocketManager` 通知、delegate、String/Data | 旧入口行为保持可用 |
| 日志 | 发送/接收与错误 | 只记录元数据，不输出完整 payload |

SwiftPM 单元覆盖优先测试消息值、缓冲策略、重连 delay 和状态快照；真实 TLS、
系统前后台和宿主网络切换需要 Xcode Simulator/真机回归。
