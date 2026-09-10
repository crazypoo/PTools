# PTools 5.8 架构状态

## 范围

本文件记录 5.8.1–5.8.9 的当前实现边界。`ptools` 仍是兼容 umbrella；5.8.1 已先落地可独立编译的 SwiftPM Core / UIFoundation 分层，5.8.2 又增加 Permission Core / Permission UI 的独立 SwiftPM 边界，并保留 Xcode/CocoaPods 的兼容源集。

PTools 面向 iOS 17+ / Swift 6。所有架构结论都以当前工作区源码和生成报告为准，不把静态扫描当作真实设备或生产验证。

## 已落地的安全切片

- Core URL 解析已经由 `PTURLParser` 提供 Foundation-only 实现，`PTBaseViewController.parseURLParameters` 保留为兼容转发。
- `PTCollectionDataCoordinator` 统一 Diffable 标识校验和 snapshot 查找，`PTCollectionView` 保留公开门面。
- `PTLRUCache` 已从 `PTCollectionView.swift` 移到 `PTCollectionViewTypes.swift`，并保留原公开类型名。
- `PTNetworkConfig` 支持稳定的现代字段名和实例初始化；Session、重试和下载配置在创建时读取实例快照。
- `PTPermission` 提供 `currentStatus()`、`requestStatus()` 和 `openSettings()`，旧 callback/旧设置入口继续保留。
- 媒体层新增 Sendable 资源描述符、URLSession 图片加载适配器和值类型视频缩略图请求；原有 UIKit/PhotoKit API 未删除。
- 导航管理器通过 proxy 复用宿主 `UINavigationControllerDelegate`，不再直接覆盖宿主 delegate。
- TabBar 外观新增值快照和 `PTTabBarVisualStyle`，旧 `PTAppBaseConfig.share` 继续兼容。
- Core 日志新增 `PTLogging`/`PTOSLogger` 值类型契约；CocoaLumberjack、LocalConsole 和运行时调试能力仍属于兼容诊断边界。
- swizzle 使用集中注册表，避免同一交换被重复执行。
- `PToolsCore` 已提供 Foundation-only 的 URL 解析、并发值类型和关联对象存储；`PToolsUIFoundation` 独立承载 SnapKit 布局辅助，`ptools` 通过 re-export 保持旧导入方式。
- `PToolsPermissionCore` 只包含权限状态、结果、错误、请求协议和设置 URL；独立系统权限 target 直接依赖它，不再依赖 SwiftPM 的 `ptools` umbrella。PhotoLibrary 源码因仍属于 Core 兼容集合，暂不重复声明同一路径 target。
- `PToolsPermissionUI` 只提供可选的权限 UI 状态值、设置页桥接和 UIKit 适配入口；旧 `PermissionCore` UI 类型继续留在 `ptools`，用于保持 CocoaPods/Xcode 兼容。
- Location handler 和 Bluetooth handler 只负责系统代理生命周期；请求完成前清空回调并解除 delegate，避免授权回调重复或异步请求永久悬挂。

## 暂缓项

以下项目需要独立 target、完整 Xcode 工程成员和人工回归，不能用同文件声明伪装完成：

- 旧 `PTPermissionCell`、`PTPermissionHeader`、`PTPermissionViewController` 等 UIKit 类型从兼容 `PermissionCore` 源集迁移到 `PToolsPermissionUI`；当前先提供不依赖 legacy Base/List 的 UI 边界，避免引入反向依赖。
- CocoaPods/Xcode 仍使用兼容源集；Core/UIFoundation 在这些入口中的独立 framework module membership 需要后续单独迁移。
- CocoaPods/Xcode 中每个权限 subspec 从 monolithic `ptools` 中移除依赖，并把独立 Permission Core/UI framework 纳入工程成员；SwiftPM 已完成该依赖方向切片。
- Network 全量 instance pipeline、HUD plugin 和 callback/stream API 迁移。
- CollectionView 的 layout、prefetch、skeleton、interaction、refresh、side-index coordinator 全量迁移。
- MediaViewer / PhotoPicker 去除 Network 硬依赖，以及 Editor 全量 protocol 注入。
- LocalConsole 的 scene-scoped debug window 和 CocoaLumberjack 独立 Diagnostics target。

这些暂缓项已在依赖图和重复入口报告中保留为迁移任务，不删除公开 API，也不引入未经验证的 target 改动。

## 验证入口

- `report/spm_dependency_graph.md`
- `report/cocoapods_subspec_graph.md`
- `report/module_parity_5_8.md`
- `report/dependency_direction_5_8.md`
- `report/file_size_5_8.md`
- `PUBLIC_API_5_8.json`
- `SENDABLE_EXCEPTIONS_5_8.md`
- `PERFORMANCE_BASELINE_5_8.md`
- `report/build_validation_5_8_9.md`

Xcode 构建若被外部 Pods 阻断，只能标记为环境阻断；不得宣称 PTools 源码和真实项目已经完成发布验证。
