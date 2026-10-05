# PTools 5.62 Application Infrastructure Security Audit

## Scope

本审计覆盖 Database、Auth、Transfer、Sync、StoreKit、Observability、WebBridge、Map、AppIntegrity、Remote Configuration 和 Realtime。目标平台为 iOS 17+ / Swift 6。

## 已完成的静态控制

- 业务层没有新增 `try!`、`as!` 或 `nonisolated(unsafe)`。
- 网络、认证和远程配置的动态值在并发核心边界使用 `Sendable` 快照。
- WebBridge 校验允许的方法、主 frame、origin、payload 大小和导航 scheme。
- 日志复用 `PTLogRedactor`，不把 Authorization、Cookie、Token 等敏感字段写入持久化 sink。
- App Integrity 不伪造 App Attest 或 DeviceCheck 成功；不支持时返回明确错误。
- StoreKit 未验证交易不会进入权益结果；finish 行为由 `PTStoreVerificationPolicy` 控制。

## 待宿主验证

- App Attest assertion / challenge replay 需要真实设备和服务端签名验证。
- WebBridge origin 与 CSP 组合需要宿主 App 的真实域名验证。
- StoreKit 交易、退款、grace period 和 billing retry 需要 StoreKit Configuration 或沙盒账户验证。

## 结论

静态安全边界已落地，且 iOS Simulator Debug / Release 构建通过；真机、外部服务和生产密钥相关证据不能由本仓库构建替代，发布前必须补齐 `report/runtime/5.62.0/`。
