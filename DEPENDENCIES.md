# PTools 5.9.x 依赖与供应链清单

当前仓库基线：5.8.9。Core 是 PooTools.podspec 的 default_subspec，其他模块均
围绕 Core 扩展。本文记录依赖所有权、版本约束和 6.0 评估状态，不修改第三方源码。

## Swift Package Manager

| 依赖 | 使用边界 | 当前约束 | 5.9.x 状态 |
| --- | --- | --- | --- |
| SwiftDate | Core 日期扩展 | exact 7.0.0 | 保留 |
| SnapKit | Core/Base/UI 布局 | exact 5.7.1 | 保留 |
| SwifterSwift | Core 扩展 | from 8.0.0 | 评估 API 使用范围 |
| CocoaLumberjack | Core 日志 | from 3.8.0 | 保留 |
| DeviceKit | Core 设备信息 | from 5.8.0 | 保留 |
| AttributedString | Core/Button 文本 | 固定 revision d8a72a7 | 已移除 master 分支 |
| Kingfisher | Core 图片加载 | exact 8.9.0 | 保留 canonical 入口 |
| SmartCodable | Core/Network 模型 | from 4.0.0 | 评估 Swift 6 兼容性 |
| KakaJSON | Network 兼容层 | exact 1.1.2 | 只允许停留在 legacy 边界 |
| Lottie | Core/组件动画 | from 4.4.0 | 保留 |
| Alamofire | Network | from 5.8.0 | 保留，禁止绕过执行器 |
| NotificationBanner / MarqueeLabel | UI 扩展 | exact/from | 保留 |
| Kitura Swift-JWT | CheckUpdate | exact 4.0.0 | 评估是否移除 Kitura 链 |
| KituraContracts / LoggerAPI / Blue* | 间接或兼容边界 | 当前解析 | 独立记录外部构建阻断 |
| SocketRocket | SocketKit | 固定 revision fe86ec0 | 已移除 spm-support 分支 |

## CocoaPods

- Podfile.lock 当前 PooTools 版本为 5.8.9。
- Bugly、Metal 搜索路径、部分 Pods Swift 6 诊断属于外部构建环境问题，不能归因于
  PooTools Core 源码，也不能通过修改 Pods 源码解决。
- 版本同步前使用 pod install --no-repo-update；本轮不擅自更新依赖版本。

## 供应链决策

1. 不接受不可复现的 branch 依赖；manifest 使用版本或 revision。
2. Bugly 必须提供模拟器 slice 和通用 device archive 后，才允许进入完整 Simulator 矩阵。
3. Kitura 只在实际源代码依赖确认后保留；现阶段先记录 Swift 6 诊断阻断，不删除传递依赖。
4. SmartCodable/KakaJSON 的动态解析入口必须在兼容层隔离，避免 Any 穿过 actor。

## 未完成验证

当前尚未完成：

- 真实宿主项目的依赖解析和归档。
- Bugly XCFramework 的供应商替换。
- Kitura 和 SmartCodable 的最终 6.0 删除决策。
