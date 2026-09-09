# PTools 5.9.x 架构基线

## 边界

PooTools.podspec 的 default_subspec 是 Core。Core 提供基础模型、场景解析、主线程
桥接、图片/媒体适配、日志和 UI 基础扩展；Network、PhotoPicker、VideoEditor 等
模块通过 Core 扩展，不应反向把业务状态写入 Core。

## 唯一入口

| 能力 | 入口 | 兼容层 |
| --- | --- | --- |
| 场景和当前页面 | PTSceneContext | UIApplication/UIViewController 旧查询 |
| UI 调度 | PTMainActorBridge | PTGCDManager、DispatchQueue.main.async |
| 网络图片 | PTLoadImageFunction.loadImage(source:) | 控件和字符串加载方法 |
| 视频缩略图 | PTVideoThumbnailService | AVAsset、FileManager 旧入口 |
| 媒体保存 | PTMediaSaveService | UIImage/PHPhotoLibrary 旧入口 |
| 空状态 | PTUnavailableManager.render | BaseViewController/CollectionView 适配 |
| 网络请求 | Network 内部请求上下文 | requestApi、KakaJSON、Body 旧入口 |

## 并发边界

- UI 控制器、配置和 UI completion 在 MainActor。
- NetworkCache、RequestDeduplicator 等共享资源使用 actor。
- 跨 actor 只传 Data、URL、String、数值和不可变快照。
- 系统对象兼容包装器必须登记在 unchecked sendable allowlist。
- 业务模型不新增 nonisolated(unsafe) 或 unchecked Sendable。

## 5.9.x 的结构变化

- PTProgressSnapshot、PTResponseMetadata 增加 Equatable，便于契约和回归测试。
- PTSceneContext 增加 PTSceneContextProviding 和默认实现，允许新代码注入场景解析。
- PTAlertManager 支持注入场景解析提供器；动态通知、暗黑模式时间选择器和基类横竖屏
  请求复用 PTSceneContext，减少重复的全局窗口搜索。
- 网络配置和 URL、导航、图片配置入口补充正确命名的 canonical API。
- 网络内存缓存增加数量和成本上限，避免大响应无限占用内存。
- SwiftPM 增加 PToolsCoreTests 契约测试目标；Xcode scheme 移除指向不存在的旧测试 target。

## 延期项

Network、PTCollectionView、BaseViewController 和 VideoEditor 的大文件拆分需要独立
批次和每批 Xcode 构建；本轮不进行高风险大规模重写。真实设备、真实宿主项目和运行时
性能结果仍需单独验证。
