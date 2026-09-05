# PTools 5.x Core 治理路线图

> 基线：`5.7.4`（2026-09-05，当前工作区基线）
> 当前候选：`5.7.5`（2026-09-05，待完整构建验收）
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

- ✅ `CORE-560-01`：新增 Core 源文件契约检查，逐项对比 CocoaPods、SwiftPM 和
  `PooTools-Example` Xcode target 的 28 个 Core 目录与实际 261 个源文件。
- ✅ `CORE-560-02`：完成 `String+PTEX.swift` 密码强度算法的职责拆分；保留原有
  `passwordLevel` 符号和评分行为，不扩大原有公开 API。
- ✅ `CORE-560-03`：重复入口报告改为带校验的分类清单；补齐 5.x 唯一实现入口、兼容
  包装器、迁移 pending 和 6.0.0 删除门槛文档。
- ✅ `CORE-560-04`：建立 6.0.0 删除 deprecated 动态入口和历史兼容层的必要条件；
  5.x 继续保留 `PTAlertDebugView`、旧媒体保存回调和 Network 动态入口。
- ✅ `CORE-560-05`：`5.6.0` tag 已存在，作为本轮 ScrollBanner 和 PageControl 的基线。
  Xcode 完整构建仍可能被外部 Pods 的 Swift 6 诊断阻断，阻断记录不归因于 Core 源码。

### 5.6.0 实施与验证说明

- ✅ `Scripts/validate_core_source_contract.sh` 使用现有 CocoaPods `xcodeproj` 工具链
  读取 Xcode source membership；不新增运行时依赖，不修改 Pods 源码。
- ✅ `Scripts/report_duplicate_entries.sh` 现在会校验每组 canonical、兼容包装器、语义差异、
  pending 和 6.0.0 removal gate，质量扫描会自动执行该校验。
- ✅ 新增 [MIGRATION_5X.md](MIGRATION_5X.md)，并将 README、RELEASE、CHANGELOG 的
  版本和迁移入口补齐到 5.6.0 已发布基线与 5.6.1 候选状态。
- ⚠️ 质量扫描、源文件契约和 Package manifest 可执行；完整 Xcode 构建尚未通过，阻断来自
  外部 `SmartCodable`/`swift-syntax`，不能据此宣称源码和发布验收完成。

## 5.6.1：ScrollBanner 与 PageControl 稳定性和功能统一

### 第一批：PageControl 边界、动画和无障碍

- ✅ `CORE-561-01`：统一自定义 PageControl 的进度动画为单个共享 `CADisplayLink`，移除各
  子类重复的动画引擎，补充离屏停止和 Reduce Motion 处理。
- ✅ `CORE-561-02`：校验页数、进度、半径、间距和尺寸输入，修复零页、非法尺寸和越界点击
  的布局风险；`PTScrollingPageControl` 的宽度计算改为按真实圆点数量计算。
- ✅ `CORE-561-03`：补齐调整型无障碍操作、页码值同步和图片指示器的 generation/实例校验，
  避免异步图片回调写入已经复用的圆点。

### 第二批：PTBannerView 唯一实现入口

- ✅ `CORE-561-04`：空数据、非水平滚动、无限循环中间定位、索引计算、标题高度缓存、导航
  箭头、自动轮播和媒体播放统一由 `PTBannerView` 处理。
- ✅ `CORE-561-05`：Cell 复用时清理播放器、播放按钮和旧回调；视频封面通过
  `PTVideoCoverCache`/`PTVideoThumbnailService` 生成，并用配置代际保护旧结果。
- ✅ `CORE-561-06`：统一 `reloadData` 后处理流程，避免调用不存在的 UIKit completion API，并
  以 generation 忽略过期刷新任务；空数据刷新不再残留分页器和标题视图。

### 第三批：PTCycleScrollView 兼容迁移

- ✅ `CORE-561-07`：将 `PTCycleScrollView` 改为 `PTBannerView` 的 deprecated 兼容适配器，保留
  原有公开属性、工厂方法、回调和滚动入口，旧调用转发到统一实现。
- ✅ `CORE-561-08`：兼容旧版任意箭头资源、自定义箭头 frame、纯标题背景图和旧 PageControl
  配置；内部不再维护重复的 ScrollView/Cell 实例化逻辑。
- ✅ `CORE-561-09`：确认仓库无 `PTCycleScrollViewCell` 调用后移除该内部 Cell 及其 Xcode source
  membership，减少重复实现和无效播放器状态。

### 第四批：验证、文档和版本元数据

- ✅ `CORE-561-10`：更新路线图、迁移说明入口、README、RELEASE、CHANGELOG、podspec 和
  Podfile.lock 到 `5.6.1` 候选版本；未修改第三方依赖版本或 Pods 源码。
- ✅ `CORE-561-11`：完成修改文件语法解析、质量扫描、Core source contract、构建入口检查和
  `git diff --check`。
- ⛔ `CORE-561-12`：Xcode Debug/Release 完整构建仍被外部 Pods 的 `KituraContracts` Swift 6
  并发错误阻断（`BodyFormat` 非 Sendable、共享 formatter），因此暂不创建 `5.6.1` tag。

### 5.6.1 实施与验证说明

- ✅ PageControl、ScrollBanner 源文件未新增 `as!`、`try!`、`nonisolated(unsafe)` 或
  `@unchecked Sendable`；新增跨异步回调均有主线程和代际保护。
- ✅ 4 批源码改动均使用临时 DerivedData 执行过 Xcode 构建；PooTools 源码未出现编译错误，
  最终失败均发生在外部依赖 target。补充的 PooTools framework 构建同样在外部 `Appz` 的
  Swift 6 主 actor conformance 错误处停止。
- ⛔ 在 `KituraContracts`、`Appz` 等外部依赖恢复或提供兼容产物前，不能宣称完整 Xcode
  Debug/Release 验收通过，也不能创建或推送 `5.6.1` 标签。

## 5.6.2：Language 通知链路稳定性修复

### 任务清单

- ✅ `CORE-562-01`：修复 `PTLanguage.share.language` 的有效语言比较；同一有效语言重复赋值不通知，异常存储值在比较时安全归一化。
- ✅ `CORE-562-02`：统一 `LanguageDidChangedKey` 的主线程投递；主线程保持同步通知，非主线程通过 `PTMainActorBridge` 回到主线程。
- ✅ `CORE-562-03`：将 UIViewController 和 UIView 的语言监听改为独立通知 token，支持重复注册、显式移除、宿主对象销毁自动清理和注册时立即回调。
- ✅ `CORE-562-04`：保持 `ChangedBlock`、`pt_observerLanguage`、`pt_viewObserverLanguage` 和 `PTLanguage.share.language` 等公开兼容入口不变；本轮未新增 `@unchecked Sendable`、`nonisolated(unsafe)`、`try!` 或 `as!`。
- ✅ `CORE-562-05`：完成修改文件语法解析、Swift 6 安全扫描、Core source contract、构建入口检查、重复入口检查和 `git diff --check`。
- ✅ `CORE-562-06`：同步 `PooTools.podspec`、`Podfile.lock`、`README.md`、`MIGRATION_5X.md`、`CHANGELOG.md` 和本路线图到 `5.6.2` 候选版本。
- ✅ `CORE-562-08`：兼容 Xcode String Catalog；`.localized()` 使用 Foundation 的
  `LocalizedStringResource` 解析 `.xcstrings`，并保留 `.strings/.lproj` 与自定义 tableName
  的兼容回退。
- ⛔ `CORE-562-07`：Xcode Debug/Release 完整构建未完成；Release 在外部
  `KituraContracts` 的 Swift 6 并发诊断处阻断（`BodyFormat` 非 Sendable、共享
  `_iso8601Formatter`，并伴随相关 Sendable 警告），Debug 停留在外部 Pods 依赖准备阶段。
  该阻断不属于 PooTools 源码，未创建 `5.6.2` tag。

### 5.6.2 实施与验证说明

- ✅ `PTLanguage` 使用锁保护语言值和有效语言归一化；通知只在有效语言真正改变后发送。
- ✅ 语言监听不再把 UIViewController/UIView 自身作为 selector observer，避免宿主侧移除其他通知时误删语言监听；独立 token 在显式移除和对象销毁时清理。
- ✅ `.localized()` 通过 `LocalizedStringResource` 支持新 Xcode String Catalog；旧资源 bundle
  和旧公开调用方式继续保留。
- ✅ 修改文件新增注释均使用英语、西班牙语和中文；公开符号、默认行为和兼容调用方式保持不变。
- ✅ 静态检查和 Swift 前端解析通过；Xcode Release 已执行到外部依赖编译阶段，最终被
  `KituraContracts` 的 Swift 6 并发诊断阻断；Debug 在外部 Pods 依赖准备阶段未完成。

## 5.6.3：ScreenShot 与 MessageKit 稳定性和性能治理

### 任务清单

- ✅ `CORE-563-01`：统一 UIView、UIScrollView、UITableView、UIWindow 和 WKWebView 的截图协议入口；保留原有公开方法和默认参数。
- ✅ `CORE-563-02`：增加当前场景缩放、无效尺寸和最大像素数校验，避免 Core Graphics 因零尺寸、非法尺寸或超大位图产生崩溃和内存峰值。
- ✅ `CORE-563-03`：重做滚动视图长截图的分页渲染；不修改 View frame，恢复原始 contentOffset，异步入口支持取消和 WebView 延迟渲染。
- ✅ `CORE-563-04`：为 MessageKit 消息模型、聊天 Section 和 Row 建立稳定 Diffable 身份；公共列表刷新只重配置旧 Row，不随机重建整表。
- ✅ `CORE-563-05`：治理文本、媒体、地图、文件、音频和 Typing Cell 的复用状态；清理旧手势、倒计时、播放器、快照、进度任务和动画。
- ✅ `CORE-563-06`：为图片、视频、地图、文件和音频异步结果增加代次校验、取消传播或安全的 MainActor 回调，避免结果回写到错误 Cell。
- ✅ `CORE-563-07`：补齐 MessageKit 的 Nib/Storyboard 初始化和空输入兜底，移除本模块新增路径中的强制崩溃风险。
- ✅ `CORE-563-08`：完成修改文件语法解析、Swift 6 安全扫描、Core source contract、构建入口检查和 `git diff --check`。
- ✅ `CORE-563-09`：同步 `PooTools.podspec`、`Podfile.lock`、`README.md`、`MIGRATION_5X.md`、`CHANGELOG.md` 和本路线图到 `5.6.3` 候选版本。
- ⛔ `CORE-563-10`：Xcode Debug/Release 完整构建未完成；Debug 的 PooTools Swift 源码已完成编译，但最终链接被外部 `PooTools.framework` 缺失和 Metal 工具链搜索路径阻断，Release 则被外部 `KituraContracts` 的 Swift 6 并发错误阻断，因此不创建 `5.6.3` tag。

### 5.6.3 实施与验证说明

- ✅ ScreenShot 统一使用 `PTSnapshotRenderer` 做场景缩放、透明度、像素上限和渲染器配置；专用类型入口只做兼容转发。
- ✅ ScrollView/TableView 长截图在分页渲染期间保留原层级和 frame；任务结束、取消和失败时恢复滚动位置。
- ✅ MessageKit 列表改用稳定 Section/Row 身份，`PTCollectionView.showCollectionDetail` 对旧 Row 使用 `reconfigureItems`，兼顾内容刷新和增量更新。
- ✅ Cell 异步回调均有复用代次保护；可取消的 AVAsset、地图和进度任务在复用时停止，不能取消的旧兼容回调只允许通过代次校验。
- ✅ 修改文件均通过 Swift 前端语法解析，质量扫描、构建入口检查、Package manifest 和 `git diff --check` 通过。
- ⛔ Xcode Debug 已完成 PooTools Swift 源码编译，但最终链接受外部 `PooTools.framework` 缺失和 Metal 搜索路径阻断；Release 在外部 `KituraContracts` 的 Swift 6 并发诊断处停止。未进行真机或运行时人工回归。

## 5.6.4：Button 模块稳定性、性能和功能统一

### 任务清单

- ✅ `CORE-564-01`：为 `PTLoginDescButton` 增加基于 `AttributedString` 的左右富文本入口；保留原有纯文本配置、动作回调和默认布局，并对富文本动作范围提供无障碍兼容。
- ✅ `CORE-564-02`：统一 `PTLayoutButton` 的 normal、selected、highlighted 和 disabled 状态优先级；异步图片加载增加取消、代次校验、进度边界和状态重置。
- ✅ `CORE-564-03`：修复 `PTActionLayoutButton` 的 coder 初始化、动态图片重复请求、旧状态残留、负尺寸约束和重复刷新；保留旧拼写入口并提供正确的兼容方法。
- ✅ `CORE-564-04`：收敛 `PTSortButton` 的排序状态渲染、箭头图片、约束刷新、异步图片代次和可访问性，移除重复状态分支和不安全初始化路径。
- ✅ `CORE-564-05`：修复 `PTCollectionAnimationButton` 在 Auto Layout 后使用零尺寸图层、清空宿主图层和重复创建动画资源的问题；补齐 coder、动态颜色和 Reduce Motion 边界。
- ✅ `CORE-564-06`：修复 `PFloatingButton` 清理调用方长按手势、轨迹计时器互相覆盖、移除回调重复触发和拖动状态残留；降低轨迹快照频率并支持 Reduce Motion 归边。
- ✅ `CORE-564-07`：完善 `PTMenuSheetArrowButton` 的尺寸变化、方向重绘、动态颜色和 Reduce Motion；`PTMenuSheetButtonView` 支持菜单项尺寸、边距、对齐、高亮图文、无障碍和可逆动画。
- ✅ `CORE-564-08`：完成修改文件 Swift 前端解析、质量扫描和 `git diff --check`；本轮未新增 `try!`、`as!`、`nonisolated(unsafe)` 或未登记的 `@unchecked Sendable`。
- ⛔ `CORE-564-09`：已执行 Xcode `PooTools` Debug 以及 `PooTools-Example` Simulator Debug/Release；当前使用干净 DerivedData 的构建在外部 `Pods/KituraContracts` 的 Swift 6 并发诊断处提前阻断。此前依赖缓存可用的一次构建曾完成 PooTools 源码编译和类型检查，但最终链接仍被设备版 `Pods/Bugly/Bugly.framework` 与缺失 Metal 工具链搜索路径阻断，因此不创建 `5.6.4` tag。

### 5.6.4 实施与验证说明

- ✅ `PTLoginDescButton` 的富文本由 `AttributedString` 解析为动作范围；无动作文本仍可使用整侧兼容回调，左右内容为空时不会留下空布局占位。
- ✅ Layout、Action、Sort 按钮的状态渲染均以单一入口计算，异步图片结果不会覆盖新的状态或复用后的内容；负尺寸、空图片和 coder 场景都有安全兜底。
- ✅ Collection Animation 的动画图层现在挂在私有容器中，布局尺寸变化只更新现有图层；浮动按钮轨迹不再通过共享 Timer 互相取消，移除通知保持幂等。
- ✅ MenuSheet 菜单项改用私有原生内容布局，完整消费 `PTMenuSheetButtonItems` 的尺寸、边距、标题对齐、图片模式和高亮配置，不依赖 iOS 15 已弃用的 UIButton edge-inset API。
- ✅ 代码注释遵循英语、西班牙语、中文三语约定；未修改第三方依赖和 Pods 源码。
- ⚠️ 当前静态检查和此前依赖缓存构建均未发现 PooTools 本批新增 warning/error；最新干净 DerivedData 的 Debug/Release 构建被外部 `KituraContracts` Swift 6 诊断提前阻断，依赖恢复后还需继续验证 PooTools 源码和最终链接。已知最终链接还受设备版 Bugly 产物及缺失 Metal 工具链搜索路径影响，待提供兼容依赖产物后补齐 Debug/Release 完整链接验证和发布标签。

## 5.6.5：ImagePicker 与 PhotoPicker 共存、边界拆分和媒体入口统一

### 任务清单

- ✅ `CORE-565-01`：确认 ImagePicker 与 PhotoPicker 的职责边界；ImagePicker 负责轻量单媒体系统选择和相机，PhotoPicker 保留多选、编辑、原图、Live Photo 和自定义浏览能力，不删除任一公开模块。
- ✅ `CORE-565-02`：为 ImagePicker 增加独立 CocoaPods subspec 与 SwiftPM product/target；PhotoPicker 改为依赖 ImagePicker，QRCodeScan 显式使用 ImagePicker 的类型化入口。
- ✅ `CORE-565-03`：新增 `PTSystemMediaPicker`、`PTSystemMediaPickerKind`、`PTSystemMediaPickerResult` 和 `PTSystemMediaPickerError`；媒体结果只跨异步边界传递 Sendable 数据或调用方持有的临时视频 URL。
- ✅ `CORE-565-04`：统一相机权限、相机 metadata 解析和 PhotoPicker 内嵌相机的完成路径；补充媒体类型校验、失败回调、取消处理和 exactly-once 防护。
- ✅ `CORE-565-05`：图片库使用 PHPicker 单选，拍摄使用 UIImagePickerController；视频在 provider 回调结束前复制到唯一临时文件，GIF/图片保留原始数据，Live Photo 在轻量系统入口返回静态图片。
- ✅ `CORE-565-06`：保留 `PTImagePicker` 泛型 Controller、旧 openAlbum/photograph 和 PhotoPicker 旧符号兼容入口；旧便利方法增加弃用迁移提示，迁移目标为 `PTSystemMediaPicker`，兼容层至少保留到 6.0.0。
- ✅ `CORE-565-07`：扩展重复入口报告、质量扫描和三套构建契约检查，登记 picker strategy canonical、兼容包装器、语义差异和 6.0.0 删除门槛。
- ✅ `CORE-565-08`：完成修改文件 Swift 前端解析、ImagePicker iOS 17 SDK 类型检查、质量扫描、Core source contract、构建入口检查和 `git diff --check`。
- ⛔ `CORE-565-09`：Xcode `PooTools` Debug、`PooTools-Example` Debug/Release 均已重新执行但未完成；三次最新构建都在外部 `KituraContracts` Swift 6 并发错误处阻断，不能创建 `5.6.5` tag 或宣称完整构建验收通过。

### 5.6.5 实施与验证说明

- ✅ ImagePicker 与 PhotoPicker 已拆为可独立消费的边界：CocoaPods 使用 `PooTools/ImagePicker`，SwiftPM 使用 `PooToolsImagePicker`；PhotoPicker 仅保留自定义 PhotoKit UI 和其业务依赖。
- ✅ `PTSystemMediaPicker` 将动态字典限制在 UIKit delegate 边界；`PTCameraCapturePayload` 统一解析图片、图片 URL 和视频 URL，异步 provider 回调通过 Sendable MainActor 投递闭包返回结果。
- ✅ `PTMediaLibCameraContainerViewController` 继续使用自定义相机承载和统一 `PTMediaSaveUI` 保存服务；权限请求、取消、保存失败和重复 delegate 回调都有明确终态。
- ✅ 修复当前 Xcode SDK 下动态 `UTType(identifier:)` 的兼容问题，改用 `NSItemProvider` 的公开类型符合性查询，不调用仅 iOS 27 可用的初始化器。
- ✅ 当前静态门禁、构建契约、Package manifest、ImagePicker Simulator 类型检查和 diff 检查通过；完整 Xcode 构建的外部阻断已记录，不修改第三方 Pods 源码和依赖版本。

### 5.6.5 当前阻断记录

- ⛔ `PooTools` Debug 和 `PooTools-Example` Debug 在外部 `Pods/KituraContracts/Sources/KituraContracts/BodyFormat.swift` 的 Swift 6 并发诊断处停止，属于依赖 target 的非 Sendable 全局状态问题。
- ⚠️ `PooTools-Example` Release 曾因本机磁盘空间耗尽（`No space left on device`）停止；本轮已清理临时 DerivedData，最新 Release 结果已推进到同一处外部 `KituraContracts` 并发错误。
- ⛔ 在上述阻断解除、完整构建矩阵通过前，不同步 `PooTools.podspec`/`Podfile.lock` 到 5.6.5，不创建 `5.6.5` tag。

## 发布前固定检查

- `bash Scripts/validate_build_entries.sh`
- `bash Scripts/validate_core_source_contract.sh`
- `bash Scripts/validate_release.sh <version>`
- `bash Scripts/validate_quality_scans.sh`
- `git diff --check`
- Xcode `PooTools-Example` Debug / Release 完整构建。
- 只有对应版本章节没有 `🚧`、`⬜` 或 `⛔` 时，才允许创建同名 tag。

## 5.6.6：ImageEditor 稳定性、性能与导航栏样式治理

### 任务清单

- ✅ `CORE-566-01`：修复 `PTEditImageViewController` 自定义导航栏样式未生效的问题；导航栏容器绑定所属 `UINavigationController`，`apply(style:)` 与 `updateTransition(progress:)` 共用同一套渲染逻辑，保留 `.solid(.clear)` 和转场渐变效果。
- ✅ `CORE-566-02`：完善编辑完成流程；增加可选的类型化结果回调，保留旧 `editFinishBlock`，对导出任务增加取消、生命周期和 exactly-once 保护，避免重复回调和页面离开后的旧任务回写。
- ✅ `CORE-566-03`：增加图片输出策略和尺寸上限；默认对超大结果降采样，支持原尺寸和自定义上限，并对无效图片尺寸、像素数量和渲染失败提供明确错误类型。
- ✅ `CORE-566-04`：修复绘制、马赛克、裁剪和贴纸的非法几何输入；校验零尺寸、非有限尺寸、非法缩放、路径比例、裁剪范围和贴纸边界，避免 Core Graphics 和 CGFloat 转换触发崩溃。
- ✅ `CORE-566-05`：优化编辑渲染性能；缓存马赛克底图，合并调节滑块高频渲染任务，限制滤镜缓存成本，移除编辑器对共享滤镜纹理尺寸的依赖，并让前景分割只跨任务传递图片 `Data`。
- ✅ `CORE-566-06`：修复导出期间贴纸交互状态被永久改变的问题；导出前临时隐藏操作控件和计时器，渲染结束后恢复原有选中、操作和定时器状态。
- ✅ `CORE-566-07`：修复裁剪界面和文字输入界面的布局稳定性；键盘通知改为更新 SnapKit 约束，补充坐标转换、无效键盘 frame、裁剪缩放和内容偏移保护。
- ✅ `CORE-566-08`：消除 ImageEditor 对全局 `PTMediaLibConfig.share` 的临时修改；新增实例级媒体选择策略，图片替换使用单图配置，避免编辑器和其他 PhotoPicker 实例互相污染。
- ✅ `CORE-566-09`：补齐 ImageEditor 独立 SwiftPM/CocoaPods 模块边界；显式声明 `PooToolsHarbethKit`、`PooToolsPhotoPicker` 依赖，公开共享滤镜 Cell 所需 API，不修改第三方依赖和 Pods 源码。
- ✅ `CORE-566-10`：完成修改文件的 Swift 6 安全扫描、Core source contract、构建入口检查、Package manifest 检查和 `git diff --check`。
- ⛔ `CORE-566-11`：完整 Xcode Simulator 构建的 PooTools Swift 源码已编译通过，但最终链接仍被外部设备版 `Pods/Bugly/Bugly.framework` 和缺失 Metal 模拟器工具链搜索路径阻断；未创建 `5.6.6` 标签，也未宣称完整构建验收通过。
- ✅ `CORE-566-12`：修复自定义导航栏渐变在状态栏与导航栏交界处重复起算造成的颜色断层；系统导航栏外观保持透明，由绑定的自定义容器使用 `updateTransition(progress:)` 的同一渲染结果连续覆盖状态栏和导航栏。

### 5.6.6 实施与验证说明

- ✅ `PTNavigationBarContainer` 不再读取全局当前导航控制器作为渲染目标；每个容器绑定自己的导航栈，页面级样式和交互式转场可以同时工作。
- ✅ 编辑导出仍在 MainActor 使用 UIKit 图层完成，取消只会终止当前任务；新类型化结果区分成功、取消和失败，旧回调保持兼容。
- ✅ 绘制、马赛克、裁剪、贴纸、滤镜和前景分割均增加边界校验；滤镜渲染使用当前图片尺寸生成纹理，减少共享可变状态造成的数据竞争。
- ✅ PhotoPicker 的编辑器入口使用实例配置快照，未再覆盖全局配置；原有公开符号、默认参数和模块路径保持不变。
- ✅ 新增代码注释遵循英语、西班牙语和中文三语约定；没有修改 Pods 源码、第三方依赖版本、Podfile.lock 或 Xcode 工程文件。
- ⚠️ `validate_quality_scans.sh`、`validate_build_entries.sh`、`validate_core_source_contract.sh`、Package manifest 和差异检查通过；Xcode 源码编译结果通过，但外部链接环境修复前仍需补做 Debug/Release 完整链接和真机人工回归。

## 5.6.9：UIView 圆角与 Cell 复用稳定性强化

### 任务清单

- ✅ `CORE-569-01`：盘点 `viewCorner`、`viewCornerRectCorner` 和 `removeViewCorner` 的调用时机，确认 Cell 初始化、配置和复用阶段的状态覆盖规则。
- ✅ `CORE-569-02`：统一半径和部分等半径圆角使用原生 `CALayer` 快速路径，不再因为 Auto Layout 尚未完成而依赖零尺寸 Tracker。
- ✅ `CORE-569-03`：胶囊和不同圆角半径继续使用布局 Tracker，在首次有效 bounds、尺寸变化和窗口变化后更新路径，并限制重复路径生成。
- ✅ `CORE-569-04`：保存圆角渲染状态，处理动态边框颜色的 trait 变化；清理圆角时不影响同一 Tracker 上的渐变和进度条能力。
- ✅ `CORE-569-05`：修正自定义边框路径的半边框几何计算，校验非法半径、边框宽度和零尺寸输入。
- ✅ `CORE-569-06`：修复 `PTDarkModeControl` 和 `PTActionSheetController` 的复用样式残留，统一通过 `removeViewCorner()` 清理圆角状态。
- ✅ `CORE-569-07`：在圆角公开入口补充英、西、中三语调用时机说明，明确 Auto Layout、Cell 复用和无样式状态的推荐用法。
- ✅ `CORE-569-08`：完成修改文件解析、质量扫描、构建入口、Package manifest 和差异检查；PooTools Debug/Release 源码编译阶段未发现本批新增错误。
- ⛔ `CORE-569-09`：完整 Simulator 链接仍被外部设备版 `Pods/Bugly/Bugly.framework`、缺失 Metal Simulator toolchain 和外部 `SmartCodable` 构建诊断阻断；外部流程已同步 `PooTools.podspec` 并创建 `5.6.9` tag，但该 tag 不能视为完整验收通过，`Podfile.lock`、README 和 RELEASE 仍待发布流程统一。

### 5.6.9 实施与验证说明

- ✅ 常见 `viewCorner(radius:)` 调用可在创建 View 后、约束前执行；圆角半径和边框会立即写入 Layer，Cell 后续布局不会丢失样式。
- ✅ 胶囊、不同半径和动态尺寸样式等待有效布局后渲染；Tracker 仅在圆角、渐变或进度能力仍被使用时保留。
- ✅ `removeViewCorner()` 可安全用于复用配置，清除圆角、边框、mask 和 iOS 26 corner configuration，不会移除同一 View 的渐变或进度状态。
- ✅ 未改变公开方法签名、模块路径或第三方依赖；未新增 `@unchecked Sendable`、`nonisolated(unsafe)`、`try!` 或 `as!`。
- ⛔ Debug/Release 均已通过 Xcode 执行到 PooTools 源码编译阶段；完整链接和源码警告门禁仍受外部依赖/工具链阻断，待环境修复后补验。

## 5.7.0：PTListViewController 列表容器与滚动边界统一

### 任务清单

- ✅ `CORE-570-01`：新增 `PTListViewController`，以一个 `PTCollectionView` 同时承载类表格和类集合列表；`.Normal` 保持纵向列表语义，其余布局类型继续由 `PTCollectionView` 负责，不引入第二套 `UITableView` 数据源。
- ✅ `CORE-570-02`：提供 `makeListViewConfiguration()`、`configureListView(_:)`、`prepareListViewLayout(_:)` 和 `installListViewConstraints(_:)` 扩展点；默认列表约束使用安全区，特殊页面可以保留全屏布局。
- ✅ `CORE-570-03`：保持 `PTCollectionView` 对内部 `UICollectionViewDelegate` 的所有权，通过内部滚动观察通道复用 `PTBaseViewController` 的大标题 inset、进度和回弹逻辑，不覆盖业务 delegate。
- ✅ `CORE-570-04`：迁移 `PTPermissionViewController` 和 `PTDarkModeControl` 两个样板页面；保留权限关闭按钮、装饰视图、深色模式页眉页脚、特殊 inset 和原有数据回调行为。
- ✅ `CORE-570-05`：将新 Base 源文件加入 CocoaPods、SwiftPM 和 Xcode 的 Core 源文件契约；不修改公开类名、原有入口和第三方依赖。
- ✅ `CORE-570-06`：补齐 5.7.0 迁移文档、重复入口记录和注释规范；新代码注释使用英语、西班牙语和中文。
- ⛔ `CORE-570-07`：Xcode `PooTools-Example` Debug/Release 和 `PooTools` Debug 已执行，但被外部 `KituraContracts` 的 Swift 6 并发诊断阻断；在依赖修复前不得创建 `5.7.0` tag 或宣称完整构建验收通过。

### 5.7.0 实施与验证说明

- ✅ `PTListViewController` 不伪造 section/row，不修改 Diffable snapshot，不触发额外 Cell 注册或业务回调；子类只需配置继承的 `listView`。
- ✅ 默认安全区布局与 `PTPermissionViewController` 的关闭按钮布局、`PTDarkModeControl` 的全屏布局均通过 override 分离，避免基类为特例增加条件分支。
- ✅ 列表控制器的滚动回调通过 `PTCollectionView` 内部桥接执行，既保留 `collectionViewDidScroll`/`collectionDidEndDragging` 公开回调，也避免把 delegate ownership 转移给控制器。
- ✅ 公开的 `bindScrollView` 继续使用原有入口；大标题计算被抽为基类内部辅助方法，直接绑定和包装列表使用同一套进度计算。
- ⛔ 当前完整 Xcode 构建失败原因位于 `Pods/KituraContracts` 的外部 Swift 6 并发诊断，不属于本次新增或修改的 PooTools 源码；源码解析、工程列表检查和修改文件的编译路径需要在依赖修复后补验。

### 5.7.0 发布门槛

- ⬜ 外部 Pods 阻断解除后重新执行 PooTools-Example Debug/Release 和 PooTools Debug 完整构建。
- ⬜ 通过 `validate_quality_scans.sh`、`validate_build_entries.sh`、`validate_core_source_contract.sh`、Package manifest、CocoaPods lint 和 `git diff --check`。
- ⬜ 完成 Normal、Custom/Grid、空状态、大标题滚动、列表 delegate 回调和两个迁移页面的人工回归。
- ⬜ 将 `PooTools.podspec`、`Podfile.lock`、`README.md`、`RELEASE.md` 和 `CHANGELOG.md` 同步到 5.7.0 后，创建不带 `v` 前缀的 `5.7.0` tag。

## 5.7.1：PTCustomerAlertController 多按钮自适应布局（修复重做）

### 任务清单

- ✅ `CORE-571-01`：保留 `UIAlertController.base_alertVC` 和 `PTCustomerAlertController` 公开接口，使用展示场景的实际窗口宽度计算正文尺寸，兼容旋转和分屏。
- ✅ `CORE-571-02`：多按钮弹窗改为自适应布局；一到两个按钮保持横向布局，三个及以上按钮使用纵向布局，并在内容过高时启用按钮区域或整体内容滚动。
- ✅ `CORE-571-03`：限制弹窗宽高在安全区域内，保护零尺寸、超大内容和旋转后的重新布局；重复布局只更新约束常量，不重复创建按钮和视图层级。
- ✅ `CORE-571-04`：修复约束激活顺序；标题和自定义内容视图在建立约束前加入 `bodyContentView`，确保所有约束两端存在共同父视图，避免 `NSGenericException` 闪退。
- ✅ `CORE-571-05`：按钮点击和背景关闭保持一次性回调，保留旧索引语义；默认背景颜色继续使用动态系统磨砂颜色。
- ✅ `CORE-571-06`：完成修改文件 Swift 前端解析、质量扫描、构建入口检查、Core source contract、`git diff --check` 和 Xcode PooTools Debug/Release 构建。
- ⚠️ `CORE-571-07`：示例工程 Simulator Debug 仍被仓库现有真机版 `Pods/Bugly/Bugly.framework` 阻断；通用 iOS 真机目标 Release 已构建成功，待提供兼容 Simulator 的 Bugly 产物后补做模拟器运行回归。

### 5.7.1 修复说明

- ✅ 本次闪退根因是 `configureContentHierarchy()` 在 `titleMessage` 和 `customView` 尚未加入 `bodyContentView` 时，提前激活了它们与 `bodyContentView` 的约束；现已调整为先建立完整视图层级，再激活约束。
- ✅ 初始化宽高约束不再使用强制解包；弹窗宽度和高度均有最小值保护，并优先遵循展示窗口的安全区域。
- ✅ 不修改 `5.7.1` 既有 tag，不覆盖用户提交历史；当前修复保留在工作区，确认人工回归后再由发布流程决定是否创建后续修复 tag。

## 5.7.5：Picker 嵌入能力、选择状态与安全布局治理

### 任务清单

- ✅ `CORE-575-01`：以 `PTBasePickerView` 为唯一展示容器，保留原有 `show()` 与三个具体 Picker 的公开入口；不删除公开类型，不引入第二套滚轮实现。
- ✅ `CORE-575-02`：新增显式宿主入口 `show(in:animated:)`，支持把 Picker 添加到任意 `UIView`；嵌入模式不依赖当前 Window，弹出模式继续复用 `PTSceneContext.activeWindow()`。
- ✅ `CORE-575-03`：为 String、Date、Tree Picker 增加只配置不展示的 `configure(...)`，并用稳定的内部选中状态替代直接读取 `UIPickerView` 的临时行号；空数据、越界索引和动态列变化均安全处理。
- ✅ `CORE-575-04`：统一 `canConfirm`、取消、展示代次和幂等 dismiss；嵌入模式不被 `dismiss()` 擅自移除，弹出模式的动画完成回调不会清理新一轮展示。
- ✅ `CORE-575-05`：修复日期 Picker 的季度、年周、月周和不完整时间模式的日期构造；补充反向范围、不可表示日期和边界日期的明确状态，不使用 `try!`、`as!` 或强制解包。
- ✅ `CORE-575-06`：统一三个滚轮 Picker 的 Label 样式和动态系统背景色；标题宽度改为基于按钮锚点的安全约束，避免长标题越界和跨层级约束异常。
- ✅ `CORE-575-07`：修正 SwiftPM Picker target 的直接依赖声明，扩展重复入口报告和质量扫描范围；新公开 API 注释遵循英语、西班牙语和中文三语约定。
- ✅ `CORE-575-08`：完成修改文件 Swift 6 前端解析、Package manifest、构建入口、重复入口、质量扫描和 `git diff --check`；PooTools target 的 Xcode Simulator 源码编译通过。
- ⛔ `CORE-575-09`：PooTools-Example 的完整 Debug/Release 链接和 Picker 人工运行回归仍需在外部 Pods、模拟器版依赖和工具链可用后完成；未同步 5.7.5 版本元数据或创建 tag。

### 5.7.5 实施与验证说明

- ✅ `PTStringPickerView`、`PTDatePickerView` 和 `PTTreePickerView` 现在都可以先 `configure(...)`，再由调用方使用 Auto Layout 添加到普通页面；需要覆盖层时才调用 `show(in:)` 或兼容的 `show()`。
- ✅ `show(in:)` 会校验宿主层级、先建立完整视图树再激活约束，并从宿主底部之外开始动画；重复 show/dismiss 不会让旧动画回调移除新实例。
- ✅ 日期和树形数据的内部数组均使用安全下标和空值保护；日期 Picker 对默认日期、范围和周历语义使用同一套构造与校验路径。
- ✅ Picker 依赖边界与 `Core` 一致，没有引入 DarkMode、PhotoPicker 或其他高层模块依赖；没有修改第三方依赖、Pods 源码、Podfile.lock 或 Xcode 工程文件。

### 5.7.5 发布门槛

- ⬜ 外部依赖阻断解除后重新执行 PooTools-Example Debug/Release 完整构建和 Picker 人工回归。
- ⬜ 验证普通、Grid 不适用的滚轮嵌入页面、弹出展示、长标题、空数据、日期范围、树形联动、旋转、深色模式和 Reduce Motion。
- ⬜ 通过 `validate_release.sh 5.7.5` 后，再同步 podspec、Podfile.lock、README、RELEASE、CHANGELOG 并创建不带 `v` 前缀的 `5.7.5` tag。
