# 5.62.0 Runtime Evidence

当前仓库已完成代码和 iOS Simulator 构建入口准备。本轮在 2026-10-05 使用 iOS Simulator arm64 对 `PooTools-Example` 执行 Debug / Release 完整构建并通过；Foundation-first 的应用基础设施 SwiftPM targets 也通过了目标构建检查。

当前执行环境尚未提供真实设备、App Attest/StoreKit 沙盒、后台 relaunch 或外部 SSE/HTTP 服务证据。macOS 上运行完整 SwiftPM 测试时，现有 UIKit 目标（包括 `PooToolsRealtime` 的 SocketKit 传递依赖）无法导入 UIKit，因此脚本将其标记为 host blocker，而不是伪造通过。

请在宿主工程补充：

- iPhone 真机：App Integrity、Photo/Media 权限、后台 Transfer、前后台生命周期。
- StoreKit Configuration / Sandbox：购买、退款、过期、grace period、billing retry。
- 可控 HTTP/SSE 服务：Remote Configuration、401 replay、Retry-After、Last-Event-ID。
- Xcode Instruments：数据库、Transfer、WebBridge、Realtime 的数值基线。

本目录不写入伪造的成功日志。
