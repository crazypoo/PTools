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

- ⬜ 统一 `PTMainActorBridge`、`PTGCDManager` 和可取消延迟，删除已确认的重复主线程跳转。
- ⬜ 统一 `PTSceneContext` 的活动窗口、当前页面和多场景回退策略。
- ⬜ 收敛权限、UserDefaults、配置和缓存的 actor/锁边界，建立 `@unchecked Sendable` allowlist。
- ⬜ 将跨 actor 的动态字典和 Progress 替换为 Sendable 快照，保留兼容包装器。

## 5.3.0：Base 与列表基础设施

- ⬜ 治理 `PTBaseViewController`、`PTBaseNavControl`、`PTBaseTabBarViewController` 的导航、生命周期、状态栏、空状态和页面辅助职责。
- ⬜ 治理 `PTCollectionView` 的 Diffable snapshot、布局、预取、分页、骨架和增量刷新，保证 stable ID。
- ⬜ 统一 `PTFusionCell`、`PTFusionCellModel`、复用视图、Cell option、装饰视图和列表辅助入口。
- ⬜ 在保持公开 API 的前提下拆分大文件，补充列表性能和复用回归。

## 5.4.0：图片、媒体与 Category 性能

- ⬜ 完善类型化图片加载管线，统一尺寸、缓存、取消、GIF、视频帧和错误结果。
- ⬜ 优化 PhotoKit、GIF、视频导出和原图数据的峰值内存与生命周期。
- ⬜ 统一 `UIView` 圆角/布局辅助和 `UIImage`、`String`、`Data`、`Date`、文件 URL 算法，避免重复实现。
- ⬜ 对高频 Category 保留兼容包装器并补充 iOS 17 行为回归。

## 5.5.0：视觉与交互组件

- ⬜ 统一 Alert、ActionSheet、FloatPanel、SideMenu 的内容布局、背景材质、生命周期和重复代码。
- ⬜ 统一 DarkMode、Colors、Font 的动态颜色和 trait 变化处理。
- ⬜ 治理 Badge、Button、Switch、Animation、Blur 的默认值、布局、动画取消和可访问性。

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
