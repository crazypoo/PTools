# PTools 5.x Core 治理路线图

> 基线：`5.1.0`（2026-08-29）  
> 目标范围：`PooTools.podspec` 的 `default_subspec = "Core"` 及其声明的全部子目录。  
> 版本策略：5.1.x 以稳定性和兼容性修复为主，5.2.x 以后按职责分阶段演进。

## 状态约定

- ✅ 已完成并通过该项验收
- 🚧 当前正在实施
- ⬜ 待实施
- ⛔ 被外部依赖或环境阻断

## 范围与不可变约束

- Core 范围包含：`Core`、`Blur`、`ActionsheetAndAlert`、`Base`、`AppStore`、`ApplicationFunction`、`BlackMagic`、`Button`、`Category`、`Log`、`StatusBar`、`Protocol`、`Animation`、`PermissionCore`、`PhotoLibraryPermission`、`AppDelegate`、`Foundation`、`Language`、`DarkMode`、`Line`、`Badge`、`Rotation`、`Switch`、`Colors`、`Font`、`FloatPanel`、`SideMenuControl`、`iCloud`。
- 保留现有公开符号、默认参数、模块路径和兼容入口；旧入口只能通过代理和弃用提示逐步迁移。
- 不升级第三方依赖、不修改 Pods 源码、不新增 XCTest 或 Swift Testing target。
- 每个代码批次都必须执行 Xcode Debug/Release 完整构建；静态扫描和语法解析不能替代构建。
- Xcode 构建中的第三方 Pods、链接器和工具链问题必须单独报告，不得伪装成 PooTools 源码通过。
- 新注释遵循英、西、中三语；只在并发、生命周期和兼容边界需要时添加注释。

## 5.0.0：历史版本回溯

- ✅ 完成 Core 大版本基线升级，替换动画依赖路径，调整图片加载与 iOS 17 / Swift 6 构建契约。

## 5.0.1：历史版本回溯

- ✅ 修复媒体、启动广告、并发边界和缓存相关的稳定性问题。

## 5.1.0：历史版本回溯

- ✅ 分离模型协议，建立图片加载、视频缩略图、媒体保存、场景上下文和 MainActor 调度的 canonical 入口，并完成高频 Base/Category 的兼容拆分。

## 5.1.1：稳定性修复与兼容回归

### 任务清单

- ✅ `CORE-511-01`：建立并持续维护本路线图；补齐 5.0.0、5.0.1、5.1.0 历史记录；在 README 和 RELEASE 中提供入口；发布检查阻断未完成任务。
- ✅ `CORE-511-02`：稳定 `PTMediaSaveService` 的授权、编码、Photos 事务、资源标识回读和 exactly-once completion。
- ✅ `CORE-511-03`：启用 `PTLaunchADSnapshot`，冻结启动广告时间、媒体、GIF/Data、视频 URL、图片标识和点击元数据，避免序列计时依赖可变模型。
- ✅ `CORE-511-04`：对 5.1.0 拆分的 Base、Category、UIImage、UIView、String 代码执行公开符号、访问级别、资源注册和运行时层级回归。
- ✅ `CORE-511-05`：只清理 Core 范围内已确认的嵌套 MainActor/主队列跳转，不进行机械式全仓迁移。
- ✅ `COMPAT-511-01`：修复 Network 旧请求入口的参数日志环境判断；测试/调试环境输出脱敏参数，App Store 环境隐藏参数与响应体。
- ✅ `COMPAT-511-02`：修复 `PTMediaRequestCoordinator` 以请求 ID 字符串误取消请求的问题，直接取消真实 PhotoKit request ID。
- ✅ `COMPAT-511-03`：修复 `PTBannerScheduler` 的共享状态声明和可配置自动滚动间隔，避免 `nonisolated(unsafe)` 与固定 2 秒间隔。
- ⛔ `CORE-511-06`：完成全部验证后同步到 `5.1.1`，仅在源码构建和发布门禁均通过时创建 `5.1.1` tag；当前被 Simulator 警告门禁中的外部 `SmartCodable` target 构建失败阻断，因此暂不修改版本号和创建 tag。

### 验收门槛

- PooTools 源码无新增 Swift 6、iOS 17、Clang 警告和错误。
- Core 业务路径不新增 `nonisolated(unsafe)`、`try!`、`as!` 或未登记的 `@unchecked Sendable`。
- 媒体保存、启动广告、图片请求、Network 旧入口和 Banner 回归通过。
- `Package.swift`、CocoaPods 和 Xcode 的 iOS 17 / Swift 6 构建契约一致。
- `git diff --check`、质量扫描、Xcode Debug/Release 完整构建通过；外部依赖阻断需单独记录。

### 5.1.1 当前阻断记录

- ⛔ Simulator Debug/Release 源码警告门禁在构建外部 `SmartCodable` target 时失败；该错误来自 Pods，不属于 PooTools 源码。本轮 generic iOS 的 PooTools-Example Debug/Release 已通过，但在外部依赖恢复前不能宣称 5.1.1 发布验收通过。

## 5.2.0：Core 并发与生命周期边界

- ✅ 统一 `PTMainActorBridge`、`PTGCDManager` 和可取消延迟，删除已确认的重复主线程跳转。
- ✅ 统一 `PTSceneContext` 的活动窗口、当前页面和多场景回退策略。
- ✅ 收敛权限、UserDefaults、配置和缓存的 actor/锁边界，建立 `@unchecked Sendable` allowlist。
- ✅ 将跨 actor 的动态字典和 Progress 替换为 Sendable 快照，保留兼容包装器。

### 5.2.0 实施与验证说明

- ✅ Core 调度入口已统一到 `PTMainActorBridge`；`PTGCDManager` 保留兼容方法，并增加定时器代际保护和安全纳秒上限。
- ✅ 场景窗口、根控制器和当前页面已统一由 `PTSceneContext` 解析；无根控制器的 delegate window 不再作为有效回退。
- ✅ UserDefaults 使用同步锁保护的泛型 Sendable 存储；权限回调统一经过 MainActor 桥接；配置和视频封面缓存沿用 MainActor/actor 边界。
- ✅ Core 已使用 `PTProgressSnapshot`、`PTResponseMetadata` 等值类型；旧动态 API 继续保留在兼容层，不跨入并发核心执行器。
- ⛔ Xcode Debug/Release 已完成 PooTools 源码编译，但模拟器最终链接被外部 `Pods/Bugly/Bugly.framework` 真机构建产物阻断；因此本轮不创建版本 tag，也不宣称完整构建验收通过。

## 5.3.0：Base 与列表基础设施

- ✅ 治理 `PTBaseViewController`、`PTBaseNavControl`、`PTBaseTabBarViewController` 的导航、生命周期、状态栏、空状态和页面辅助职责。
- ✅ 治理 `PTCollectionView` 的 Diffable snapshot、布局、预取、分页、骨架和增量刷新，保证 stable ID。
- ✅ 统一 `PTFusionCell`、`PTFusionCellModel`、复用视图、Cell option、装饰视图和列表辅助入口。
- ✅ 在保持公开 API 的前提下收敛现有 extension 职责，补充列表性能和复用保护；未新增风险性 PBX 文件。

### 5.3.0 实施与验证说明

- ✅ 导航栏容器现在让紧凑导航栏和大标题区域共用同一套 solid、gradient、transparent 样式；`PTTestChatViewController` 的白色大标题背景不再透明。系统导航栏同步设置大标题字体和文字颜色。
- ✅ `PTCollectionView` 统一 PhotoKit 预取与取消的资源映射，使用布局环境宽度适配 Tag 横竖屏变化，限制无效补充视图尺寸，并避免重复输出布局回退日志。
- ✅ `PTFusionCellModel` 使用稳定存储的 Diffable 身份；Fusion Cell 复用清理、装饰视图 shadowPath 缓存和 `PTImageCell` 图片请求代际保护已统一，减少错误回写与重复布局。
- ✅ 未删除或改名公开符号，未引入第三方依赖和测试 target；现有 Base extension 拆分继续复用，避免为拆分而扩大 `private` 状态可见性或修改工程文件。
- ⛔ `PooTools-Example` Debug / Release 已执行完整 Xcode 构建，PooTools 源码均完成编译；最终模拟器链接被外部 `Pods/Bugly/Bugly.framework` 的真机产物阻断，因此不宣称完整 Xcode 验收通过，也不创建 5.3.0 tag。

## 5.4.0：图片、媒体与 Category 性能

- ✅ 完善类型化图片加载管线，统一尺寸、缓存、取消、GIF、视频帧和错误结果。
- ✅ 优化 PhotoKit、GIF、视频导出和原图数据的峰值内存与生命周期。
- ✅ 统一 `UIView` 圆角/布局辅助和 `UIImage`、`String`、`Data`、`Date`、文件 URL 算法，避免重复实现。
- ✅ 对高频 Category 保留兼容包装器并补充 iOS 17 行为回归。

### 5.4.0 实施与验证说明

- ✅ `PTLoadImageFunction` 支持目标尺寸下采样、GIF 安全解码、视频第 10 帧入口、取消传播和 Live Photo 临时文件清理；旧入口保持兼容。
- ✅ `PTVideoThumbnailService` 成为视频缩略图异步入口；`AVAsset` 导出使用真实 Documents URL，避免 URL 构造错误和重复临时文件。
- ✅ 高频 Category 的图片、日期、数据、查询参数和视频首帧逻辑已收敛；日期格式化不再依赖共享可变 formatter，GIF 解码降低中间图像缓存峰值。
- ✅ PooTools 源码已通过当前 Xcode Debug / Release 编译阶段；最终模拟器链接仍被外部真机版 `Pods/Bugly/Bugly.framework` 阻断，待提供 Simulator 或 XCFramework 产物后补齐最终链接验证。

## 5.5.0：视觉与交互组件

- ✅ 统一 Alert、ActionSheet、FloatPanel、SideMenu 的内容布局、背景材质、生命周期和重复代码。
- ✅ 统一 DarkMode、Colors、Font 的动态颜色和 trait 变化处理。
- ✅ 治理 Badge、Button、Switch、Animation、Blur 的默认值、布局、动画取消和可访问性。

### 5.5.0 实施与验证说明

- ✅ Alert、ActionSheet、FloatPanel 和 SideMenu 统一使用场景感知的动态系统背景；Alert 场景解析复用 `PTSceneContext`，FloatPanel 移除通知监听，透明子控制器也有稳定的背景兜底。
- ✅ DarkMode 优先读取活动窗口 trait；SSBlurView 和 PTFrostedGlassView 复用已创建的效果资源，支持 Reduce Motion、trait 变化和离屏动画清理。
- ✅ Badge 动画参数、PTSwitch 尺寸与状态、PTLayoutButton 动态颜色和布局、字体输入参数统一做安全兜底；动画取消与 VoiceOver 状态同步得到补强。
- ✅ 修改文件已完成 Swift 前端语法解析，`swift package dump-package`、质量扫描、三套构建契约检查和 `git diff --check` 通过。
- ⚠️ 当前 Xcode Debug / Release 均已通过 PooTools 源码编译阶段，但最终模拟器链接仍被既有真机版 `Pods/Bugly/Bugly.framework` 阻断；本轮未修改 Pods 或第三方依赖，待提供 Simulator/XCFramework 产物后补齐最终链接验证。

## 5.6.0：依赖、源码契约与 6.0 准备

- ⬜ 对比 CocoaPods Core、SwiftPM 和 Xcode source membership，消除源文件漂移。
- ⬜ 继续拆分超大文件，降低跨模块耦合和内部可见性扩散。
- ⬜ 完成兼容入口弃用周期、迁移文档、重复方法报告和发布门禁。
- ⬜ 评估 6.0.0 删除 deprecated 动态入口和历史兼容层的必要条件。

## 发布前固定检查

- `bash Scripts/validate_build_entries.sh`
- `bash Scripts/validate_release.sh <version>`
- `bash Scripts/validate_quality_scans.sh`
- `git diff --check`
- Xcode `PooTools-Example` Debug / Release 完整构建。
- 只有对应版本章节没有 `🚧`、`⬜` 或 `⛔` 时，才允许创建同名 tag。
