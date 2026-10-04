# PTools 5.61.0 Runtime Safety / Scene / Concurrency 收口

本版本面向 iOS 17+ / Swift 6+，收口 Core 及其直接扩展的运行时安全、Scene 所有权和并发边界。

## 已完成

- Kakapos 从 SwiftPM、CocoaPods、锁文件和生产源码移除；C7 视频导出改用 AVFoundation/PTools 入口。
- HeartRate 的相机、输入输出、像素处理和权限失败改为可恢复错误。
- NetworkSpeedTest 改为显式 endpoint、actor 会话、类型化快照和取消。
- Ping 增加状态机和 `PTPingSession`，修复无地址/不支持地址族的错误路径。
- UI 入口移除生产代码中的 `AppWindows!`；定位使用 `PTLocationSnapshot`，旧键保留迁移窗口。
- `PTStorage` 文件 I/O 使用 utility 队列，UserDefaults 兼容入口不再调用 `synchronize()`。
- `@unchecked Sendable` 继续使用集中 allowlist 和分类登记，新增 AVFoundation sample buffer 包装器有明确不变量。
- 新增 `PTSplitViewController` 和 Router 自适应桥接，支持 double/triple column、compact push、regular secondary、Inspector 和状态恢复。
- 新增语义能力归属清单、工作树安全报告和 5.61.0 发布门禁。

## 验证边界

静态扫描、SwiftPM manifest、CocoaPods 依赖生成和 Example Simulator Debug/Release 构建证明代码与
依赖契约可构建；不能替代真机相机、真实测速服务、Ping 网络、iPad Stage Manager、Instruments
或宿主业务回归。这些证据必须由集成方在对应环境补充，不能被脚本结果伪装成已完成。
