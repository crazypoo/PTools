# PTools 6.0 之前完整升级与架构优化路线图

> 项目：PTools / PooTools
> 仓库：`https://github.com/crazypoo/PTools`
> 路线图制定日期：2026-09-08
> 审查基线：`master` @ `226e1b8f`（2026-09-10）
> 当前 Podspec 版本：`5.9.6`
> 当前最新 Git Tag：`5.9.6`（2026-09-10）
> 最低平台：iOS 17.0
> Swift：Swift 6.0 / Strict Concurrency
> 核心原则：**5.x 完成内部重构、解耦、兼容迁移和门禁建设；6.0 只做已经准备好的破坏性删除与正式模块边界切换。**

---

# 0. 这份路线图解决什么

PTools 5.x 已经完成了不少重要治理：

- Swift 6 / iOS 17 基线。
- `PTSceneContext`。
- `PTMainActorBridge`。
- 媒体保存 canonical service。
- 图片请求、视频缩略图、异步任务 generation/cancel 保护。
- `PTBannerView` / PageControl 唯一实现入口。
- `PTSystemMediaPicker` 与自定义 PhotoPicker 职责分离。
- `PTListViewController`。
- Picker 的“配置 / 展示”拆分。
- Alert 的自适应布局、iOS 26 Glass / iOS 17 Material。
- Core source contract。
- duplicate entry / compatibility / migration gate。

因此，6.0 之前不应该继续以“重写已有控件”为主，而应该完成：

1. **Core 真正瘦身。**
2. **模块依赖方向重构。**
3. **全局状态和 Singleton 降级为便利入口。**
4. **Network / Navigation / Collection / Media 的内部职责拆分。**
5. **SPM / CocoaPods / Example 三套入口一致性。**
6. **Swift 6 并发最终收口。**
7. **测试、Benchmark、API baseline、发布门禁。**
8. **5.x deprecated → 6.0 删除路径冻结。**

---

# 1. 当前 master 的关键事实

本路线图不是从旧版本假设出发，而是基于 2026-09-08 的当前仓库结构。

## 1.1 版本元数据已经出现漂移

5.7.9 实施前审查值：

```text
PooTools.podspec        = 5.7.9
最新 Git tag            = 5.7.8
README CocoaPods 示例    = 5.6.10
RELEASE.md 当前基线      = 5.6.10 / 下一候选 5.7.0
ROADMAP_5X.md 顶部基线   = 5.7.4 / 5.7.5 candidate
master 最新提交          = d044b65
```

5.7.9 当前仓库状态：

```text
PooTools.podspec        = 5.7.9
README CocoaPods 示例    = 5.7.9
RELEASE.md 当前基线      = 5.7.9 candidate
ROADMAP_5X.md 顶部基线   = 5.7.8 / 5.7.9 candidate
MIGRATION_5X.md          = 5.7.9
Podfile.lock             = 5.7.9
最新 Git tag             = 5.7.9
```

由于 Xcode 构建矩阵仍被外部 `Pods/KituraContracts` Swift 6 并发诊断阻断，5.7.9 的发布验证记录仍需补齐；本路线图将其作为当前事实基线，并将 5.8.x 的架构改造继续置于独立门禁之后。

---

## 1.2 `ptools` Core 仍然是超级依赖中心

当前 SwiftPM `ptools` target 覆盖约 28 个目录：

```text
Core
Blur
ActionsheetAndAlert
Base
AppStore
ApplicationFunction
BlackMagic
Button
Category
Log
StatusBar
Protocol
Animation
PermissionCore
PhotoLibraryPermission
AppDelegate
Foundation
Language
DarkMode
Line
Badge
Rotation
Switch
Colors
Font
FloatPanel
SideMenuControl
iCloud
```

同时直接依赖约 18 个第三方库：

```text
SwiftDate
SnapKit
SwifterSwift
CocoaLumberjack
DeviceKit
AttributedString
IQKeyboardManager
Kingfisher
SafeSFSymbols
SmartCodable
KakaJSON
Lottie
ZipArchive
FlagKit
NotificationBanner
Instructions
IOSSecuritySuite
Popovers
```

这意味着：

```text
一个很小的模块
    ↓
依赖 ptools
    ↓
间接引入一大批本来不需要的三方能力
```

---

## 1.3 “已经拆成 Target”不等于“已经解耦”

当前大量 SwiftPM target 仍然：

```swift
dependencies: ["ptools"]
```

典型包括：

```text
CameraPermission
LocationPermission
CalendarPermission
MotionPermission
TrackingPermission
HealthPermission
ContactsPermission
MicPermission
BluetoothPermission
NotificationPermission

SearchBar
Stepper
BankCard
KeyChain
RateView
Segmented
Slider
Router
Ping
Vision
IAP
...
```

因此当前属于：

> 物理目录模块化已经比较丰富，但逻辑依赖仍高度中心化。

---

## 1.4 当前几个需要继续治理的“大对象”

当前 master 中：

```text
PTCollectionView.swift       ≈ 2186 行
Network.swift                ≈ 1778 行
PTBaseViewController.swift   ≈ 1342 行
PTTabBarView.swift           ≈ 880 行
PooTools.podspec             ≈ 950 行
Package.swift                ≈ 364 行
```

这不是单纯“文件太长”的问题，而是职责开始聚集。

### `PTCollectionView`

当前同一对象直接涉及：

```text
Diffable DataSource
Compositional Layout
Waterfall Cache
Grid / Tag / Horizontal / Custom
Skeleton
PhotoKit PHCachingImageManager
Photo prefetch
Side Index
Swipe
Context Menu
Move / Drag
Refresh
Empty State
Scroll debounce
Bounds change task
Decoration
Supplementary View
```

### `PTBaseViewController`

当前同一基类直接涉及：

```text
NavigationBar
StatusBar
Rotation
LargeTitle
Back Button
Scene / Sheet
Scroll behavior
日志
URL 参数解析
NavigationBar restore/bind
全局 UIScrollView appearance
```

### `Network`

当前仍存在：

```swift
public final class Network: @unchecked Sendable
public static let share = Network()
public var plugins: [NetworkPlugin]
public var config: PTNetworkConfig
private lazy var session: Session
```

其中 `config` 虽然有 Lock，但 `plugins` 仍是公开可变数组；而 Session 是 lazy 创建，配置修改和 Session 生命周期的语义容易产生不一致。

### `PTNavigationBarManager`

当前：

```swift
public func bind(to nav: UINavigationController) {
    if nav.delegate !== self {
        nav.delegate = self
    }
}
```

意味着 NavigationBarManager 直接拥有 `UINavigationController.delegate`，会与自定义转场、业务 delegate、TabBar 协调产生所有权冲突。

### `PTAppBaseConfig`

当前是：

```swift
@MainActor
public class PTAppBaseConfig: NSObject {
    public static let share = PTAppBaseConfig()
}
```

里面同时配置：

```text
图片 placeholder
图片加载进度
基础 margin
VC 背景
导航栏
权限 UI
TabBar
字体
颜色
iOS 26 模式
```

它现在更像“整个框架的全局 UI 状态容器”，而不是简单配置对象。

---

## 1.5 PermissionCore 目前同时包含“权限逻辑”和“权限 UI”

当前 `PermissionCore` 目录中同时存在：

```text
PTPermission.swift
PTPermissionModel.swift
PTPermissionText.swift

PTPermissionCell.swift
PTPermissionHeader.swift
PTPermissionSettingCell.swift
PTPermissionSettingHeader.swift
PTPermissionSettingViewController.swift
PTPermissionViewController.swift
```

因此它并不是真正的 Permission Foundation。

---

## 1.6 Media 模块仍存在硬依赖

当前 SwiftPM：

```text
PooToolsMediaViewer
    ├ ptools
    ├ ProgressBar
    ├ PooToolsNetWork
    ├ PageControl
    └ LivePhoto

PooToolsPhotoPicker
    ├ ptools
    ├ ImagePicker
    ├ CameraPermission
    ├ PooToolsNetWork
    ├ Loading
    └ Kakapos
```

本地媒体浏览 / 本地 PhotoKit 选择不应该天然要求 Network。

---

## 1.7 第三方依赖供应链仍有风险

当前 Package.swift 仍存在 branch dependency：

```text
AttributedString -> branch: master
SocketRocket     -> branch: spm-support
```

另外 5.x 路线图中反复出现外部阻断：

```text
KituraContracts Swift 6 concurrency
SmartCodable / swift-syntax
Bugly Simulator framework
Metal Simulator toolchain
```

6.0 之前必须把“PTools 自身质量”和“外部依赖可构建性”分开管理，但不能永久接受外部阻断作为常态。

---

# 2. 6.0 前的目标架构

建议最终依赖方向逐步变为：

```text
                    ┌──────────────────────┐
                    │     PToolsCore       │
                    │ Foundation / Runtime │
                    └──────────┬───────────┘
                               │
             ┌─────────────────┼─────────────────┐
             ▼                 ▼                 ▼
     PToolsUIFoundation  PToolsPermissionCore  PToolsNetworkCore
             │                 │                 │
      ┌──────┼───────┐         │                 │
      ▼      ▼       ▼         ▼                 ▼
 Navigation List   Theme   Permission impl   Network implementation
      │      │       │
      │      │       ├───────────────┐
      │      │                       │
      ▼      ▼                       ▼
    TabBar  Collection          MediaCore
                                   │
                      ┌────────────┼─────────────┐
                      ▼            ▼             ▼
                 MediaViewer   PhotoPicker   Image/Video Editor
```

---

# 3. 版本策略总览

## 5.7.9

**当前 master 收尾，不做大架构改动。**

主题：

```text
版本基线统一
Alert 最新修复收口
文档/发布信息纠偏
回归当前 5.7.8 → 5.7.9 差异
```

---

## 5.8.x

**Architecture Refactoring Series**

目标：

```text
真正拆依赖
拆 God Object 内部职责
降低 ptools umbrella 的中心化
建立实例级配置
```

推荐版本：

```text
5.8.0 Dependency Baseline & Packaging Contract
5.8.1 Core / UIFoundation 分层
5.8.2 Permission 与 System Service 解耦
5.8.3 Network 架构治理
5.8.4 PTCollectionView Coordinator 化
5.8.5 Navigation / BaseVC Delegate 解耦
5.8.6 Theme / TabBar / Appearance 解耦
5.8.7 Media Dependency Inversion
5.8.8 Debug / Logging / Runtime Isolation
5.8.9 5.8 架构稳定版
```

---

## 5.9.x

**6.0 Readiness Series**

目标：

```text
冻结 canonical API
收口 Swift 6
建立测试和 benchmark
清理依赖供应链
冻结 deprecated 删除清单
完整演练 6.0
```

推荐版本：

```text
5.9.0 Canonical API Freeze
5.9.1 Swift 6 Concurrency Final Audit
5.9.2 Tests / Benchmark / Regression Matrix
5.9.3 Scene / Lifecycle / Singleton Scope
5.9.4 Performance / Memory / Cache
5.9.5 Accessibility / iOS 26 / Dynamic UI
5.9.6 Third-party Supply Chain
5.9.7 Documentation / Example / Migration
5.9.8 Feature Freeze & 6.0 Rehearsal
5.9.9 Final 5.x Baseline
```

---

# 4. 5.7.9：当前 master 稳定收尾

## 目标

不要在 5.7.9 同时做 Core 大拆分。

5.7.9 只负责：

```text
把现在 master 变成一个可信的稳定起点
```

---

## 5.7.9-01 统一版本元数据

必须同步：

- [x] `PooTools.podspec`
- [x] `README.md`
- [x] `CHANGELOG.md`
- [x] `RELEASE.md`
- [x] `ROADMAP_5X.md`
- [x] `MIGRATION_5X.md`
- [x] `Podfile.lock`
- [ ] Git tag

要求：

```text
任何“当前版本 / 下一版本”只维护一个事实来源。
```

建议：

```text
CURRENT_RELEASE.md
```

不一定需要新文件，也可以让 `PooTools.podspec + Git tag` 成为唯一版本来源，其他文档只引用，不再手写“当前版本”。

---

## 5.7.9-02 Alert 回归

针对 master 最新修复验证：

- [x] Cancel 按钮最后显示（标准包装器源码顺序已确认）。
- [ ] 1 个按钮。
- [ ] 2 个按钮。
- [ ] 3+ 按钮。
- [ ] Feedback 输入框。
- [ ] `feedBackTitleHeight`。
- [ ] 长标题。
- [ ] Dynamic Type。
- [ ] iOS 17 Material。
- [ ] iOS 26 Glass。
- [ ] Reduce Transparency。
- [ ] Dark Mode。
- [ ] 横屏。
- [ ] 分屏。
- [x] callback index 与旧 API 兼容（标准包装器源码顺序已确认）。

---

## 5.7.9-03 建立“架构重构前 baseline”

输出：

```text
report/architecture_baseline_5_7_9.md
```

至少记录：

```text
SPM products count
SPM targets count
Core directories count
Core third-party dependencies count
targets directly depending on ptools
@unchecked Sendable count
nonisolated(unsafe) count
shared/share singleton count
files > 1000 LOC
deprecated public symbols count
branch dependencies count
```

---

## 5.7.9 验收

- [x] 不进行大型模块移动。
- [x] 不删除 public API。
- [x] 所有版本文档一致。
- [ ] 当前 Alert 修改人工回归完成。
- [x] `validate_build_entries.sh`
- [x] `validate_core_source_contract.sh`
- [ ] `validate_release.sh 5.7.9`（因当前路线图保留外部构建阻断项而按发布门禁预期阻断）。
- [x] `validate_quality_scans.sh`
- [x] `swift package dump-package`
- [x] `git diff --check`
- [ ] Generic iOS Device Release build（被外部 `Pods/KituraContracts` Swift 6 并发错误阻断）。
- [ ] iOS Simulator build（被外部 `Pods/KituraContracts` Swift 6 并发错误阻断，详见 `report/architecture_baseline_5_7_9.md`）。

---

# 5. 5.8.0：Dependency Baseline & Packaging Contract

## 目标

在移动 Core 文件前先建立“依赖图和模块契约”。

否则后面会不断出现：

```text
SPM 改了
Podspec 忘了
Xcode target 没加
feature 又依赖回 ptools
```

---

## DEP-580-01 自动生成 SPM Target Graph

新增脚本：

```text
Scripts/report_spm_dependency_graph.swift
```

或 Python/Ruby 脚本。

输出：

```text
report/spm_dependency_graph.md
report/spm_dependency_graph.json
```

每个 Target 记录：

```text
Target
Internal dependencies
Third-party dependencies
Source path
Resources
Swift flags
```

---

## DEP-580-02 自动生成 CocoaPods Subspec Graph

解析 `PooTools.podspec`：

```text
Subspec → PooTools subspec
Subspec → third-party pod
```

---

## DEP-580-03 SPM / CocoaPods Parity Gate

必须自动检测：

```text
SwiftPM 有产品，Podspec 没有
Podspec 有模块，SwiftPM 没有
依赖不同
源码目录不同
编译宏不同
资源不同
```

建议：

```text
Scripts/validate_module_parity.sh
```

---

## DEP-580-04 Core Dependency Budget

基线约 18 个直接第三方依赖。

建议目标：

```text
5.8.0：建立 baseline
5.8.x 结束：<= 6
5.9.x 结束：<= 3
6.0：0~2
```

不要为了数字硬删依赖；只统计真正必要依赖。

---

## DEP-580-05 Dependency Direction Rules

CI 禁止：

```text
Core -> Feature
PermissionCore -> Media
PermissionCore -> Network
UIFoundation -> PhotoPicker
Navigation -> PhotoPicker
MediaCore -> Network concrete implementation
```

---

## 5.8.0 验收

- [x] dependency graph 可自动生成。
- [x] SPM / CocoaPods parity 可自动校验。
- [x] 新 target 必须通过 dependency direction gate。
- [x] 不改业务行为。
- [x] 不改公开 API。

## 5.8.0 当前实施状态（2026-09-09）

- [x] `DEP-580-01`：新增 `report_spm_dependency_graph.rb`，生成可重复的 SPM target、源码、资源、编译设置和依赖图。
- [x] `DEP-580-02`：新增 `report_cocoapods_subspec_graph.rb`，解析当前 96 个 CocoaPods subspec 及其本地/第三方依赖。
- [x] `DEP-580-03`：新增 `validate_module_parity.sh`，记录当前 81 个可比模块、15 个 CocoaPods-only 模块、依赖差异和编译宏差异；默认检查稳定指纹，只有显式 `--update` 才能更新基线。
- [x] `DEP-580-04`：记录 `ptools` 当前 18 个直接第三方依赖的 5.8 baseline；本批不为了数字删除依赖。
- [x] `DEP-580-05`：新增 `validate_dependency_direction.sh` 和临时历史依赖白名单；当前 118 条内部依赖边中 2 条为已登记迁移边，无未登记违规。
- [x] 5.8.0 契约门禁已接入 `validate_quality_scans.sh`，并提供 `validate_58_contracts.sh` 统一执行入口。
- [x] 本批只新增检查脚本、报告和路线图状态，没有改变业务实现、公开 API、第三方依赖或 Pods 源码。

### 5.8.0 本批证据

- `report/spm_dependency_graph.md` / `.json`
- `report/cocoapods_subspec_graph.md` / `.json`
- `report/module_parity_5_8.md` / `.json`
- `report/dependency_direction_5_8.md` / `.json`
- `report/build_validation_5_8_0.md`

## 5.8.1–5.8.9 当前实施状态（2026-09-09）

本批按“可独立回滚、可验证、保持兼容”的原则落地了安全切片。以下勾选仅表示对应切片已经实现，不代表尚未完成的独立 Target 拆分或真实设备回归已经完成。

### 5.8.1 Core / UIFoundation

- [x] `CORE-581-03`：完成 URL 解析的 Foundation-only 实现，Base 控制器保留兼容转发。
- [ ] `CORE-581-01` / `CORE-581-02` / `CORE-581-05`：真正的 PToolsCore、PToolsUIFoundation 和 umbrella Target 拆分待独立 Xcode target 与模块成员验证。

### 5.8.2 Permission

- [x] `PERM-582-04`：补充 `currentStatus()`、`requestStatus()`、`openSettings()`，并用 exactly-once 桥接保证回调只恢复一次。
- [ ] `PERM-582-01` / `PERM-582-02` / `PERM-582-03` / `PERM-582-05`：权限核心、权限 UI、最小依赖 Target 和系统服务彻底分离待后续垂直切片。

### 5.8.3 Network

- [x] `NET-583-07`：重试配置改为所属 Network 实例快照。
- [x] `NET-583-08`：下载 Session 使用实例配置快照，不再从共享单例读取超时配置。
- [x] `NET-583-09`：生成 Sendable 例外报告并接入质量门禁。
- [x] `NET-583-02` 兼容切片：新增 Sendable `PTNetworkRequestEnvironment`、实例化 `performCodableRequest`，并按稳定的 header/body 快照隔离请求键和缓存键。
- [ ] `NET-583-01` / `NET-583-03`–`NET-583-06` / `NET-583-10`：不可变配置、完整插件注册表、全部请求类型统一 Pipeline、HUD 插件解耦、callback/stream 兼容迁移和完整测试仍待后续批次；本批不重写既有公开请求路径。

### 5.8.4 List

- [x] `LIST-584-01`：新增轻量 `PTCollectionDataCoordinator`，统一 Diffable 校验和 snapshot 查找。
- [x] `LIST-584-03` 兼容切片：新增 `PTCollectionPhotoPrefetchCoordinator`，按资源标识去重、引用计数取消，并在窗口移除、数据重置和内存告警时清理预取。
- [x] `LIST-584-09`：将 `PTLRUCache` 从 CollectionView 主文件移出并保持原公开类型名。
- [x] `LIST-584-10`：新增文件大小门禁和例外清单。
- [ ] `LIST-584-02` / `LIST-584-04`–`LIST-584-08`：布局、骨架、交互、刷新、侧索引和滚动协调器待逐个迁移。

### 5.8.5 Navigation

- [x] `NAV-585-01` / `NAV-585-03`：导航管理器改用代理转发宿主 delegate，不再无条件覆盖宿主回调。
- [x] `NAV-585-06`：移除基类对 `UIScrollView.appearance()` 的全局副作用。
- [ ] `NAV-585-02` / `NAV-585-04` / `NAV-585-05` / `NAV-585-07`：完整 observer、栈隔离、BaseVC 拆分和转场矩阵回归待后续批次。

### 5.8.6 Theme / TabBar

- [x] `THEME-586-01` / `THEME-586-02` / `TAB-586-07`：新增外观值快照、`PTTheme` 和统一 TabBar visual style 枚举。
- [x] `THEME-586-03` / `THEME-586-04` 兼容切片：`PTAppBaseConfig` 保留 `legacyDefault`，`PTTabBarView` 和项目项在初始化时固定 `PTTabBarAppearance` 快照，旧初始化入口保持不变。
- [ ] `TAB-586-05` / `TAB-586-06`：TabBar 内部职责完整拆分和 Lottie 适配仍待后续验证。

### 5.8.7 Media

- [x] `MEDIA-587-01` / `MEDIA-587-02` / `MEDIA-587-05`：新增 Sendable 资源描述符、图片加载协议和类型化视频缩略图请求。
- [ ] `MEDIA-587-03` / `MEDIA-587-04` / `MEDIA-587-06` / `MEDIA-587-07`：Network 反转依赖、缓存协议、任务生命周期和编辑器协议注入待后续迁移。

### 5.8.8 Debug / Logging

- [x] `DEBUG-588-01` / `DEBUG-588-04`：新增 Core 日志契约、OSLog 适配器和集中 swizzle 注册表。
- [ ] `DEBUG-588-02` / `DEBUG-588-03` / `DEBUG-588-05`：CocoaLumberjack 诊断 Target、调试代码隔离和 scene-scoped 调试窗口待后续迁移。

### 5.8.9 验证与发布

- [x] 生成架构、依赖、公开 API、Sendable 例外和性能基线报告。
- [x] 静态契约门禁、质量扫描、Package manifest 和 `git diff --check` 通过。
- [ ] Xcode Debug / Release 完整构建：被外部 `Pods/KituraContracts` 的 Swift 6 并发错误阻断，详见 `report/build_validation_5_8_9.md`。
- [ ] 真实设备、宿主项目人工回归和版本 Tag：等待外部依赖阻断解除后执行，本批不创建 `5.8.9` Tag。

### 本批证据

- `ARCHITECTURE_5_8.md`
- `DEPENDENCY_GRAPH_5_8.md`
- `PUBLIC_API_5_8.json`
- `SENDABLE_EXCEPTIONS_5_8.md`
- `PERFORMANCE_BASELINE_5_8.md`
- `report/build_validation_5_8_9.md`

### 当前阻断

Xcode 27.0 下 Debug / Release 均在外部 `Pods/KituraContracts` 编译阶段失败：`BodyFormat.json` 的非 Sendable 静态值和 `_iso8601Formatter` 的共享可变状态触发 Swift 6 并发诊断。本批不修改 Pods 源码、依赖版本或兼容编译参数，因此不把该结果计入 PooTools 源码错误，也不宣称完整构建通过。

---

# 6. 5.8.1：Core / UIFoundation 分层

## 目标

让 `ptools` 从“所有东西的容器”逐渐变成“Umbrella”。

---

## CORE-581-01 新建 PToolsCore

建议只放：

```text
Foundation helpers
PTAssociatedObjectStore
PTLock / synchronized helpers
PTMainActorBridge
PTSceneContext abstraction
safe value types
common protocol
common errors
date-independent primitive helpers
URL parsing
UserDefaults wrapper
```

### PToolsCore 原则

尽量只依赖：

```text
Foundation
OSLog（可选）
```

理想：

```text
不依赖 UIKit
不依赖 Kingfisher
不依赖 Lottie
不依赖 SnapKit
不依赖 Photos
不依赖 AVFoundation
```

---

## CORE-581-02 新建 PToolsUIFoundation

适合放：

```text
UIView 基础扩展
UIViewController 基础辅助
UIColor
UIFont
UIImage 基础操作
DynamicColor
Trait helpers
SnapKit helpers
SafeArea helpers
Accessibility helpers
```

允许：

```text
UIKit
SnapKit
```

---

## CORE-581-03 拆 `PooToolsSource/Core`

当前 Core 目录里的文件建议分类：

### Foundation / Core

```text
PTAssociatedObjectStore
PTAppUserdefault
PTPropertyWrapperFunction
PTTimeUtils（若不强依赖 UIKit）
PTUrlChange
ResponseModel（视语义）
```

### Navigation

```text
PTFullScreenPopGesture
```

### Media

```text
PTGifManager
PTLoadImageFunction
PTMediaSaveService
OSSVoice（或 Speech）
```

### Haptics / Device

```text
PTPhoneFeedBackControl
```

### UI / Feature

```text
PTUpdateTipsViewController
BorderManager
```

### Legacy / Compatibility

```text
PTGCDManager
PTUtils
```

---

## CORE-581-04 `PTBaseViewController.parseURLParameters` 移出 BaseVC

目标：

```swift
URL.pt_queryParameters
```

或：

```swift
PTURLParser.queryItems(from:)
```

5.x 保留原方法：

```swift
@available(*, deprecated, message: "Use ...")
public func parseURLParameters(...)
```

内部直接转发。

---

## CORE-581-05 `ptools` 保留为 Umbrella

5.x 继续允许：

```swift
import ptools
```

内部依赖：

```text
PToolsCore
PToolsUIFoundation
PToolsLegacyCompatibility
```

逐步减少 umbrella 的 feature dependency。

---

## 5.8.1 验收

- [ ] `PToolsCore` 可单独 build。
- [ ] `PToolsCore` 不依赖 UIKit feature。
- [ ] `PToolsUIFoundation` 可单独 build。
- [ ] 旧 `import ptools` 项目无源码修改继续编译。
- [ ] Core 第三方 dependency 明显下降。
- [ ] source contract 支持新的目录边界。

---

# 7. 5.8.2：Permission / System Service 解耦

## 当前问题

`PermissionCore` 同时包含：

```text
permission protocol/model
+
cell/header/controller UI
```

而每个权限 target 又依赖完整 `ptools`。

---

## PERM-582-01 新建真正的 PToolsPermissionCore

只保留：

```text
PTPermission
PTPermissionStatus
PTPermissionResult
PTPermissionError
permission request protocol
permission settings URL helper
permission state normalization
```

不要包含：

```text
UIView
UICollectionViewCell
UIViewController
PTAppBaseConfig
```

---

## PERM-582-02 新建 PToolsPermissionUI

移动：

```text
PTPermissionCell
PTPermissionHeader
PTPermissionSettingCell
PTPermissionSettingHeader
PTPermissionSettingViewController
PTPermissionViewController
```

依赖：

```text
PToolsPermissionCore
PToolsUIFoundation
PToolsList（如果确有需要）
```

---

## PERM-582-03 每个权限模块最小依赖

例如：

```text
PTCameraPermission
    ├ PToolsPermissionCore
    └ AVFoundation

PTLocationPermission
    ├ PToolsPermissionCore
    └ CoreLocation

PTHealthPermission
    ├ PToolsPermissionCore
    └ HealthKit
```

不再：

```text
PTCameraPermission -> ptools
```

---

## PERM-582-04 Permission callback 统一

所有权限 API 统一：

```text
currentStatus()
request()
openSettings()
```

新 API 优先 async：

```swift
func request() async -> PTPermissionStatus
```

旧 callback API 保留 wrapper。

---

## PERM-582-05 Location / Motion / Speech 等区分“权限”和“服务”

例如 Location：

```text
PTLocationPermission
PTLocationService
PTLocationUI
```

不要让：

```text
permission == location manager == geocoder == UI
```

---

## 5.8.2 验收

- [ ] 单独引入 CameraPermission 不引入 Kingfisher/Lottie/Network。
- [ ] 所有权限模块可单独 build。
- [ ] 权限 UI 可选。
- [ ] async / callback exactly-once。
- [ ] permission manager 无 delegate leak。
- [ ] denied/restricted/notDetermined/authorized 全覆盖。

---

# 8. 5.8.3：Network 架构治理

## 当前问题

当前核心状态：

```swift
Network: @unchecked Sendable
Network.share
public var plugins
public var config
lazy Session
```

需要把“线程安全”和“API 语义”统一。

---

## NET-583-01 Configuration 变成稳定 Value

建议：

```swift
public struct PTNetworkConfiguration: Sendable {
    public var requestTimeout: TimeInterval
    public var resourceTimeout: TimeInterval
    public var waitsForConnectivity: Bool
    public var retryPolicy: PTRetryPolicy
    public var cachePolicy: PTNetworkCachePolicy
}
```

初始化后：

```text
构建 Session 的字段不应随意变化。
```

---

## NET-583-02 静态 Session 配置与动态请求配置分离

### Session Configuration

```text
timeout
cache
connectivity
protocolClasses
```

### Request Environment

```text
token
language
user-agent
custom headers
base URL
```

后者通过：

```text
PTRequestAdapter
PTCredentialProvider
PTRequestInterceptor
```

注入。

---

## NET-583-03 Plugin Registry 线程安全

禁止：

```swift
public var plugins: [NetworkPlugin]
```

优先方案：

```swift
Network(
    configuration: ...,
    plugins: [...]
)
```

plugins 初始化后 immutable。

如果必须支持动态注册：

```swift
actor PTNetworkPluginRegistry
```

---

## NET-583-04 `Network.share` 变为便利默认实例

支持：

```swift
let apiNetwork = Network(...)
let uploadNetwork = Network(...)
let backgroundNetwork = Network(...)
let testNetwork = Network(...)
```

保留：

```swift
Network.share
```

但 Framework 内部新代码不要默认依赖它。

---

## NET-583-05 统一 Pipeline

建议内部：

```text
Build Request
    ↓
Adapter
    ↓
Deduplicator
    ↓
Cache Read
    ↓
Session
    ↓
Retry
    ↓
Decode
    ↓
Cache Write
    ↓
Plugin
    ↓
Typed Response
```

普通 request / body / upload / download 尽量复用同一生命周期模型。

---

## NET-583-06 HUD 从 Network 核心移出

当前 Network 直接持有：

```text
PTHudView
PTHudConfig.share
```

这是 UI 和 Network 的反向耦合。

建议：

```text
PToolsNetWork
PToolsNetworkHUDPlugin
```

Network 只发送事件：

```text
requestStarted
requestProgress
requestFinished
```

HUD Plugin 在 MainActor 显示。

---

## NET-583-07 RetryHandler 不读取全局可变配置

Retry Policy 建议在创建 Session 时 snapshot。

---

## NET-583-08 Download Session 不读 `Network.share.config`

每个 Network 实例只读自己的：

```text
self.configuration
```

避免自定义 Network 实例最终又偷偷访问 `.share`。

---

## NET-583-09 Sendable audit

重点：

```text
NetworkReachability
PTNetWorkStatus
Network
PTSafeUploadParamsBox
PTLegacyModelTypeBox
RequestDeduplicator
Cache plugin
Retry handler
```

所有 `@unchecked Sendable` 进入：

```text
report/sendable_exceptions.md
```

字段：

```text
Type
Reason
Protected State
Synchronization
Owner
Expected removal version
```

---

## NET-583-10 Network Tests

必须覆盖：

- [ ] GET / POST。
- [ ] body request。
- [ ] upload。
- [ ] download。
- [ ] cancellation。
- [ ] exactly-once completion。
- [ ] timeout。
- [ ] retry。
- [ ] exponential backoff。
- [ ] cacheOnly。
- [ ] cacheElseNetwork。
- [ ] networkElseCache。
- [ ] networkOnly。
- [ ] duplicate request。
- [ ] custom dedup key。
- [ ] plugin execution order。
- [ ] dynamic auth header。
- [ ] JSON。
- [ ] plain text。
- [ ] HTML。
- [ ] decode failure。
- [ ] HTTP failure。
- [ ] URLError。
- [ ] offline → online。

---

# 9. 5.8.4：PTCollectionView Coordinator 化

## 原则

**不重写公开 API。**

`PTCollectionView` 继续是 Facade。

---

## LIST-584-01 Data Coordinator

新类型：

```text
PTCollectionDataCoordinator
```

职责：

```text
DiffableDataSource
Snapshot
Stable ID
Section mutation
Incremental update
Reload strategy
```

---

## LIST-584-02 Layout Coordinator / Provider

拆：

```text
PTCollectionLayoutProvider
PTCollectionLayoutCache
PTWaterfallLayoutEngine
PTTagLayoutEngine
```

负责：

```text
Normal
Grid
Waterfall
Tag
Horizontal
Custom
Supplementary
Decoration
```

---

## LIST-584-03 Photo Prefetcher

把：

```text
PHCachingImageManager
PHAsset list
prefetch
cancel
generation checking
```

移出主 View。

建议：

```text
PTCollectionPhotoPrefetcher
```

---

## LIST-584-04 Skeleton Coordinator

```text
PTCollectionSkeletonCoordinator
```

负责：

```text
overlay
shimmer
Reduce Motion
layout signature
visibility
```

---

## LIST-584-05 Interaction Coordinator

负责：

```text
Selection
Swipe
ContextMenu
Move
Drag
LongPress
```

---

## LIST-584-06 Refresh Coordinator

负责：

```text
header
footer
pagination
loading
no-more-data
```

---

## LIST-584-07 Side Index Coordinator

把当前：

```text
indicator
bigTextLabel
touch index
layout
feedback
```

独立。

---

## LIST-584-08 Scroll Observer Multiplexer

`UICollectionViewDelegate` 仍由 PTCollectionView 拥有。

内部 observer：

```text
LargeTitle observer
Pagination observer
External callback observer
Analytics observer
```

避免任何 coordinator 抢 delegate。

---

## LIST-584-09 拆出 LRU Cache

当前 `PTLRUCache` 不应定义在 2186 行 CollectionView 文件顶部。

移动到：

```text
PToolsCore/Cache/PTLRUCache.swift
```

根据真实使用场景决定：

```text
@MainActor
Lock
actor
```

不要因为当前调用在 UI 就把通用 cache 永久绑定 MainActor。

---

## LIST-584-10 文件尺寸 Gate

建议：

```text
> 1000 LOC：warning
> 1500 LOC：需要 architecture exception
> 2000 LOC：CI failure（legacy allowlist 除外）
```

目标不是追求小文件，而是阻止新的 God Object。

---

## 5.8.4 验收

人工回归：

- [ ] Normal。
- [ ] Grid。
- [ ] Waterfall。
- [ ] Tag。
- [ ] Horizontal。
- [ ] Custom。
- [ ] Empty。
- [ ] Skeleton。
- [ ] Header / Footer。
- [ ] Swipe。
- [ ] ContextMenu。
- [ ] Move。
- [ ] Photo prefetch。
- [ ] Incremental Diffable。
- [ ] large dataset。
- [ ] Rotation。
- [ ] LargeTitle。
- [ ] PTListViewController。

性能不能低于 5.7.9 baseline。

---

# 10. 5.8.5：Navigation / BaseVC 解耦

## NAV-585-01 NavigationDelegateProxy

新建：

```text
PTNavigationDelegateProxy
```

成为 `UINavigationController.delegate` 的协调层。

内部支持：

```text
PTNavigationBarObserver
PTTabBarNavigationObserver
PTTransitionObserver
HostDelegate
```

---

## NAV-585-02 `PTNavigationBarManager` 不再直接抢 delegate

从：

```swift
nav.delegate = self
```

改为：

```text
proxy.register(navigationBarManager)
```

---

## NAV-585-03 Host Delegate Forwarding

业务层仍然可以拥有自己的：

```swift
UINavigationControllerDelegate
```

Proxy 负责：

```text
responds(to:)
method forwarding
animationController
interactionController
willShow
didShow
```

需要避免：

```text
递归转发
delegate 生命周期泄漏
多个 proxy
```

---

## NAV-585-04 NavigationBar 状态继续按 NavigationController 隔离

当前已经使用：

```text
NSMapTable<UIViewController, PTNavBarItem>
NSMapTable<UINavigationController, Container>
NSMapTable<UINavigationController, Style>
```

这部分原则保留。

继续补：

```text
Scene
Navigation stack
Presented navigation
Sheet embedded navigation
```

隔离。

---

## NAV-585-05 BaseVC 瘦身

逐步将以下能力移出 `PTBaseViewController`：

```text
URL parse
Rotation coordination
Navigation item building
LargeTitle observation
TabBar visibility coordination
StatusBar style calculation
```

最终希望 BaseVC 接近：

```swift
@MainActor
open class PTBaseViewController: UIViewController {
    open func setupViews() {}
    open func setupConstraints() {}
    open func setupBindings() {}
}
```

不是要求 5.8.5 一次做到最终形态，而是开始分 extension / coordinator。

---

## NAV-585-06 避免全局 `UIScrollView.appearance()` 副作用

当前 BaseVC 会设置：

```text
UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
```

需要评估这是否应该成为 Framework 全局行为。

推荐：

```text
PTBaseViewController 默认行为
!=
宿主 App 所有 UIScrollView 的全局 appearance
```

---

## NAV-585-07 转场矩阵

必须回归：

```text
push
pop
popToRoot
interactive pop complete
interactive pop cancel
present nav
dismiss nav
sheet embedded nav
multiple navigation controllers
multiple window scenes
solid → solid
solid → transparent
transparent → gradient
gradient → solid
```

---

# 11. 5.8.6：Theme / TabBar / Appearance 解耦

## THEME-586-01 拆 `PTAppBaseConfig`

建议新增：

```swift
public struct PTNavigationAppearance
public struct PTTabBarAppearance
public struct PTPermissionAppearance
public struct PTMediaAppearance
public struct PTListAppearance
public struct PTAlertAppearance
```

---

## THEME-586-02 新建 `PTTheme`

```swift
public struct PTTheme {
    public var navigation: PTNavigationAppearance
    public var tabBar: PTTabBarAppearance
    public var permission: PTPermissionAppearance
    public var media: PTMediaAppearance
    public var list: PTListAppearance
}
```

---

## THEME-586-03 `PTAppBaseConfig.share` 兼容

5.x 继续：

```swift
PTAppBaseConfig.share.tabSelectedFont = ...
```

内部写入：

```text
PTTheme.default
```

但新组件支持：

```swift
PTTabBarView(appearance: custom)
```

---

## THEME-586-04 Snapshot 语义

组件创建时：

```text
获取配置 snapshot
```

而不是每次：

```text
layoutSubviews
didSet
selection
```

都去读取全局 `PTAppBaseConfig.share`。

---

## TAB-586-05 PTTabBarView 拆内部职责

目标：

```text
PTTabBarView
  ├ PTTabBarState
  ├ PTTabBarAppearance
  ├ PTTabBarLayoutEngine
  ├ PTTabBarSelectionCoordinator
  └ PTTabBarContentRenderer
```

---

## TAB-586-06 Lottie 不作为基础 TabBar 强依赖

现有内容协议思路继续强化：

```swift
protocol PTTabBarItemContent {
    var view: UIView { get }
    func setSelected(_ selected: Bool, animated: Bool)
}
```

Lottie 是 adapter：

```text
PToolsTabBarLottie
```

而不是 TabBar 核心必须知道 Lottie。

---

## TAB-586-07 iOS 26 外观策略独立

`tab26Mode` 不要继续扩展成大量布尔值。

建议：

```swift
enum PTTabBarVisualStyle {
    case classic
    case material
    case glass
    case automatic
}
```

旧 Bool 保留 wrapper。

---

# 12. 5.8.7：Media Dependency Inversion

## MEDIA-587-01 Media Resource Model

统一：

```swift
public enum PTMediaResource {
    case image(UIImage)
    case imageData(Data)
    case localURL(URL)
    case remoteURL(URL)
    case photoAsset(...)
}
```

注意跨 actor 时不要直接传非 Sendable UIKit 对象。

可以有：

```text
UI Resource
Sendable Resource Descriptor
```

两层模型。

---

## MEDIA-587-02 Image Loader Protocol

```swift
public protocol PTImageLoading: Sendable {
    func load(_ source: PTImageSource) async throws -> PTImageResult
}
```

adapter：

```text
Kingfisher loader
URLSession loader
PhotoKit loader
Local loader
```

---

## MEDIA-587-03 MediaViewer 去 Network 硬依赖

目标依赖：

```text
PooToolsMediaViewer
    ├ PToolsMediaCore
    ├ PageControl
    ├ ProgressBar
    └ LivePhoto
```

远程下载由：

```text
PToolsNetworkMediaAdapter
```

可选提供。

---

## MEDIA-587-04 PhotoPicker 去 Network 硬依赖

检查：

```text
iCloud / remote asset progress
```

到底需要 PhotoKit 还是自建 Network。

如果只是内部辅助：

```text
移到 adapter
```

---

## MEDIA-587-05 Video Thumbnail / Cache 统一

当前：

```text
PTVideoCoverCache
PTVideoThumbnailService
VideoFileCache
MediaBrowser cell
```

整理成：

```text
PTVideoThumbnailProviding
PTVideoCaching
PTVideoResourcePreparing
```

---

## MEDIA-587-06 Media Task Lifecycle

统一规则：

```text
prepareForReuse
new generation
dismiss
view disappear
memory warning
```

必须：

```text
cancel request
cancel thumbnail
cancel network
release AVPlayer
remove observer
ignore stale completion
```

---

## MEDIA-587-07 Editor 只依赖 Media protocol

ImageEditor / VideoEditor 不直接修改：

```text
PTMediaLibConfig.share
```

这个方向在 5.6.6 已经开始做，继续扩展到所有入口。

---

# 13. 5.8.8：Debug / Logging / Runtime Isolation

## DEBUG-588-01 Core 只保留 Logging Protocol

```swift
public protocol PTLogging: Sendable {
    func log(...)
}
```

---

## DEBUG-588-02 CocoaLumberjack Adapter

移动到：

```text
PToolsDiagnostics
```

Core 不直接依赖 CocoaLumberjack。

---

## DEBUG-588-03 Debug target 不污染 Production Core

以下能力全部只能在 Debug/Diagnostics target：

```text
LocalConsole
DevMask
TouchInspector
Inspector
Crash
Leak
DebugNetwork
DebugFile
DebugColor
DebugRuler
DebugPerformance
```

---

## DEBUG-588-04 Swizzle Registry

统一：

```text
PTSwizzleRegistry
```

每个 swizzle 注册：

```text
identifier
target
selector
owner
enabled condition
undo support（如果可行）
```

---

## DEBUG-588-05 Window / Scene Scope

`PTConsoleWindow` 等按：

```text
UIWindowScene
```

管理。

不允许默认：

```text
一个全局 debugWindow 覆盖所有 Scene
```

---

# 14. 5.8.9：5.8 架构稳定版

5.8.9 不新增架构。

只做：

```text
5.8.0~5.8.8 回归
依赖图验收
编译性能记录
二进制依赖记录
真实项目验证
```

---

## 5.8.9 必须输出

```text
ARCHITECTURE_5_8.md
DEPENDENCY_GRAPH_5_8.md
PUBLIC_API_5_8.json
SENDABLE_EXCEPTIONS_5_8.md
PERFORMANCE_BASELINE_5_8.md
```

---

# 15. 5.9.0：Canonical API Freeze

从这个版本开始：

> 不再新增第二套同义 API。

---

## API-590-01 Canonical Inventory

生成：

```text
MIGRATION_6.md
```

表格：

| Capability | Canonical API | Deprecated API | Since | Remove in 6.0? |
|---|---|---|---|---|

---

## API-590-02 typo API 统一

重点登记历史命名：

```text
Meida
Bilogy
Navgation
Gobal
Requset
Threshod
Customer / Custom 混用
```

策略：

```text
5.9.x 新正确 API
旧名称 deprecated alias
6.0 决定是否删除
```

---

## API-590-03 Deprecated Wrapper 必须薄

旧入口只能：

```text
convert params
call canonical
map result
```

不能继续拥有独立实现。

---

## API-590-04 Public API Baseline

自动导出 Swift public API。

CI 规则：

```text
5.x patch/minor 不允许未登记 public symbol 删除。
```

---

# 16. 5.9.1：Swift 6 Concurrency Final Audit

## CONC-591-01 全仓扫描

统计：

```text
@unchecked Sendable
nonisolated(unsafe)
Task.detached
DispatchQueue.main.async
try!
as!
force unwrap
```

不是机械禁止，而是建立 allowlist。

---

## CONC-591-02 UI 默认 MainActor

UIKit 类型：

```text
UIView
UIViewController
UI manager
appearance
layout
navigation
```

优先整体 `@MainActor`。

---

## CONC-591-03 服务类型不要因为方便绑定 MainActor

例如：

```text
LRU Cache
Network metadata
Video metadata cache
Request dedup registry
```

应根据真实同步模型选择：

```text
actor
NSLock
OSAllocatedUnfairLock
immutable value
```

---

## CONC-591-04 跨 actor 传 Snapshot

避免：

```text
Progress
UIImage
NSMutableDictionary
PHAsset
AVAsset
UIView
```

直接跨 actor。

使用：

```text
Sendable descriptor
Data
URL
String identifier
value snapshot
```

---

## CONC-591-05 Cancellation 传到底层

要求：

```text
Task.cancel()
  ↓
URLSession/Alamofire cancel
PhotoKit cancelImageRequest
AVAsset async cancellation
thumbnail generation cancellation
```

---

# 17. 5.9.2：Tests / Benchmark / Regression Matrix

## TEST-592-01 测试 Targets

建议：

```text
PToolsCoreTests
PToolsUIFoundationTests
PToolsNetworkTests
PToolsListTests
PToolsNavigationTests
PToolsMediaTests
PToolsPermissionTests
```

---

## TEST-592-02 Collection benchmark

场景：

```text
1,000 items
10,000 items
full snapshot
incremental snapshot
rapid updates
rotation
waterfall
photo prefetch
```

记录：

```text
time
main thread duration
memory
allocations
```

---

## TEST-592-03 Network benchmark

```text
100 concurrent requests
dedup hit
cache hit
cache miss
retry
large download
cancel
```

---

## TEST-592-04 Media benchmark

```text
thumbnail cache hit
thumbnail cold start
4K image downsample
rapid swipe reuse
video prepare
memory warning
```

---

## TEST-592-05 Navigation regression harness

构造测试 NavigationController：

```text
push/pop
interactive cancel
multiple nav
host delegate
tabbar hidden/restored
```

---

# 18. 5.9.3：Scene / Lifecycle / Singleton Scope

## LIFE-593-01 全仓 Window API 扫描

逐步消除：

```text
UIApplication.shared.windows
keyWindow
connectedScenes.first
delegate.window
```

统一：

```text
PTSceneContext
```

---

## LIFE-593-02 UI 状态按 Scene 保存

重点：

```text
NavigationBar
Alert Window
Console Window
Sheet
orientation
current VC
TabBar
```

---

## LIFE-593-03 Singleton 分类

所有 `.shared` / `.share` 分成：

### A. Stateless Convenience

可以保留。

### B. Thread-safe Shared Cache

可以保留，但要有上限和清理策略。

### C. Shared Mutable Service

支持实例化。

### D. Shared Mutable UI State

尽量 Scene Scope / Instance Scope。

---

## LIFE-593-04 Framework 内部不默认依赖 Singleton

例如新代码：

```swift
let network: Network
let imageLoader: PTImageLoading
let sceneContext: PTSceneContextProviding
let appearance: PTTheme
```

通过 init 注入。

对外仍可提供默认值：

```swift
init(network: Network = .share)
```

---

# 19. 5.9.4：Performance / Memory / Cache

## PERF-594-01 Cache Inventory

盘点：

```text
NSCache
Dictionary cache
thumbnail cache
video file cache
audio cache
image cache
layout cache
network cache
URLCache
```

每个 cache 必须有：

```text
owner
thread model
count limit
cost limit
disk limit
eviction
memory warning behavior
```

---

## PERF-594-02 MainActor 重任务扫描

重点：

```text
image decode
video thumbnail
Data serialization
large JSON decode
file I/O
zip/unzip
hash
crypto
```

不能因为入口是 UI 就全部在 MainActor 做。

---

## PERF-594-03 Layout 重复工作

检查：

```text
gradient layer
glass effect
corner path
skeleton path
collection layout
navigation transition
tab selection mask
```

避免每次 `layoutSubviews` 重建对象。

---

## PERF-594-04 Memory Warning Strategy

统一处理：

```text
Media
Collection
Cache
Debug
Image editor
Video editor
```

---

# 20. 5.9.5：Accessibility / iOS 26 / Dynamic UI

## UI-595-01 Dynamic Type

重点：

```text
Alert
TabBar
NavigationBar
Picker
Permission
Collection reusable view
Editor toolbar
```

---

## UI-595-02 Reduce Motion

所有：

```text
CADisplayLink
CAAnimation
UIViewPropertyAnimator
auto-scroll
selection indicator
sheet
banner
```

遵循 Reduce Motion。

---

## UI-595-03 Reduce Transparency

所有：

```text
Glass
Blur
Material
FloatPanel
TabBar
Alert
Navigation
```

有动态不透明 fallback。

---

## UI-595-04 iOS 26 系统效果不要散落布尔值

逐渐统一：

```text
automatic
classic
material
glass
```

策略对象。

---

# 21. 5.9.6：Third-party Supply Chain

## DEP-596-01 移除 branch dependencies

优先处理：

```text
AttributedString master
SocketRocket spm-support
```

方案顺序：

1. 官方稳定 tag。
2. 官方 release branch + exact revision。
3. 自维护 fork + tag。
4. 最后才保留 branch，并必须有例外说明。

---

## DEP-596-02 Kitura 依赖评估

当前：

```text
BlueCryptor
BlueRSA
BlueECC
LoggerAPI
KituraContracts
Swift-JWT
```

需要确认：

```text
哪些能力仍在实际使用
是否可用 CryptoKit / Security / 现代 JWT 库替换
是否值得继续承担 Swift 6 维护成本
```

---

## DEP-596-03 SmartCodable / KakaJSON 双栈评估

不是要求强制删一个。

但必须回答：

```text
为什么两者都存在
哪些模块使用哪个
是否可从 Core 移到 Serialization feature
```

---

## DEP-596-04 Bugly / Binary Framework

如果仍使用：

```text
必须 XCFramework
必须 Simulator slice
必须 generic device archive
```

不能让 Example Simulator 长期不可构建。

---

## DEP-596-05 Dependency Ownership

新增：

```text
DEPENDENCIES.md
```

格式：

| Dependency | Module | Reason | Maintainer Risk | Replacement |
|---|---|---|---|---|

---

# 22. 5.9.7：Documentation / Example / Migration

## DOC-597-01 README 模块化安装

不要只列几十个 Pod 命令。

增加：

### Minimal

```text
PToolsCore
PToolsUIFoundation
```

### UIKit Base

```text
ptools
```

### Network

```text
PooToolsNetWork
```

### Media

```text
ImagePicker
PhotoPicker
MediaViewer
```

### Debug

```text
PooToolsDEBUG
```

---

## DOC-597-02 每个模块写“会带入什么依赖”

例如：

```text
CameraPermission
Direct dependencies:
- PToolsPermissionCore
- AVFoundation

Does NOT include:
- Network
- Kingfisher
- Lottie
```

---

## DOC-597-03 Example 分模块

建议页面：

```text
Core
Navigation
TabBar
Collection
Network
Media
Picker
Alert
Permission
Theme
Debug
Accessibility
```

---

## DOC-597-04 MIGRATION_6.md 完成

每个 breaking change：

```text
Before
After
Reason
Automatic migration possibility
Behavior difference
```

---

# 23. 5.9.8：Feature Freeze & 6.0 Rehearsal

从 5.9.8：

## 禁止

- [ ] 新大型控件。
- [ ] 新 Core feature。
- [ ] 新网络 subsystem。
- [ ] 新媒体编辑体系。
- [ ] 新全局 singleton。
- [ ] 新 deprecated wrapper。
- [ ] 新第三方依赖，除非用于替代旧高风险依赖。

## 允许

- [ ] Bug fix。
- [ ] Security。
- [ ] Performance。
- [ ] Accessibility。
- [ ] Migration。
- [ ] Tests。
- [ ] Dependency cleanup。
- [ ] Build fix。

---

## MIG-598-01 创建 6.0 rehearsal branch

```text
release/6.0-rehearsal
```

---

## MIG-598-02 真正删除 deprecated

只在 rehearsal branch 执行：

```text
PTCycleScrollView legacy wrapper
PTImagePicker deprecated convenience
旧 Media Save wrappers
旧 Network dynamic entry
typo aliases
重复 Alert wrappers
其他 MIGRATION_5X 已登记入口
```

不要一次删除未登记 API。

---

## MIG-598-03 用真实 App 验证

至少：

```text
PTools Example
CrazyDashboard
另一个真实业务 App
```

记录：

```text
编译错误数量
迁移耗时
常见 migration pattern
运行时差异
```

---

# 24. 5.9.9：最终 5.x 基线

5.9.9 是推荐的最后一个长期稳定 5.x。

## 只允许

```text
Critical bug
Security
Migration blocker
Build issue
Documentation
```

---

## 5.9.9 冻结以下内容

- [ ] Module graph。
- [ ] Canonical API。
- [ ] Deprecated deletion list。
- [ ] 6.0 migration guide。
- [ ] Third-party dependency list。
- [ ] Public API baseline。
- [ ] Sendable exception list。
- [ ] Performance baseline。
- [ ] SPM / CocoaPods parity。
- [ ] iOS 17 / iOS 26 regression matrix。

---

# 25. 6.0 准入条件

以下未全部满足，不建议发 6.0。

---

## Architecture

- [ ] `ptools` 不再是所有 feature 的唯一底层依赖。
- [ ] Core 第三方依赖 <= 3（目标，不是绝对硬指标）。
- [ ] PermissionCore 不包含 UI。
- [ ] Permission target 不依赖 umbrella `ptools`。
- [ ] MediaViewer 本地浏览不需要 Network。
- [ ] Network 可独立实例化。
- [ ] PTNavigationBarManager 不独占 nav.delegate。
- [ ] PTCollectionView 内部 Coordinator 化。
- [ ] PTAppBaseConfig 不再是唯一主题来源。
- [ ] Debug 不进入 Production Core。

---

## Swift 6

- [ ] 所有 `@unchecked Sendable` 有登记。
- [ ] 所有 `nonisolated(unsafe)` 有登记。
- [ ] UIKit API isolation 清晰。
- [ ] async cancellation 可传播。
- [ ] cache / registry 并发安全。
- [ ] 无已知数据竞争。

---

## API

- [ ] deprecated API 至少经过一个 5.9.x 发布周期。
- [ ] 每个删除项有 replacement。
- [ ] `MIGRATION_6.md` 有示例。
- [ ] 5.9.9 Example 不再调用待删除 API。
- [ ] 真实 App 已 rehearsal。

---

## Build

- [ ] SwiftPM Debug。
- [ ] SwiftPM Release。
- [ ] CocoaPods lint。
- [ ] Simulator Debug。
- [ ] Simulator Release。
- [ ] Generic Device Release。
- [ ] Archive。
- [ ] PTools Example。
- [ ] 无 Bugly/Kitura/SwiftSyntax 长期阻断。

---

## UI / Runtime

- [ ] iOS 17。
- [ ] 当前最新 iOS 26。
- [ ] Light。
- [ ] Dark。
- [ ] Dynamic Type。
- [ ] VoiceOver。
- [ ] Reduce Motion。
- [ ] Reduce Transparency。
- [ ] Portrait。
- [ ] Landscape。
- [ ] Split View。
- [ ] Multi Scene。

---

# 26. 6.0 建议删除内容

注意：这里只列“候选”，最终以 `MIGRATION_6.md` 冻结清单为准。

## 可以删除

### 已有 canonical implementation 的旧 wrapper

例如：

```text
PTCycleScrollView legacy API
旧 fetchImage 兼容入口
旧 media save convenience
旧 dynamic Network adapter
旧 typo aliases
```

### 已明确迁移的拼写错误

例如：

```text
Meida
Bilogy
Navgation
Gobal
Requset
Threshod
```

### 5.x 中只为兼容存在的重复实现

前提：

```text
repo 无调用
Example 无调用
real app rehearsal 无调用
migration 文档完整
```

---

# 27. 6.0 不建议为了“干净”而删除的东西

不要机械消灭：

```text
Network.share
PTNavigationBarManager.shared
PTLanguage.share
```

如果它们已经变成：

```text
可选 convenience singleton
```

而底层也支持实例化，则完全可以继续存在。

真正要删除的是：

> “只能通过全局单例才能工作”的架构限制。

---

# 28. 建议新增的质量脚本

建议最终 Scripts 至少有：

```text
validate_build_entries.sh
validate_core_source_contract.sh
validate_release.sh
validate_quality_scans.sh

validate_module_parity.sh
validate_dependency_direction.sh
validate_public_api.sh
validate_sendable_exceptions.sh
validate_deprecated_inventory.sh
validate_branch_dependencies.sh

report_dependency_graph.sh
report_large_swift_files.sh
report_singletons.sh
report_concurrency_exceptions.sh
report_public_api.sh
report_deprecated_api.sh
```

---

# 29. 推荐 Issue / Task ID 规范

继续沿用现在路线图风格，但按领域分：

```text
REL-579-xx
DEP-580-xx
CORE-581-xx
PERM-582-xx
NET-583-xx
LIST-584-xx
NAV-585-xx
THEME-586-xx
MEDIA-587-xx
DEBUG-588-xx

API-590-xx
CONC-591-xx
TEST-592-xx
LIFE-593-xx
PERF-594-xx
UI-595-xx
DEP-596-xx
DOC-597-xx
MIG-598-xx
REL-599-xx
```

这样不会再全部塞进 `CORE-xxx`。

---

# 30. 推荐每个版本的 Commit 顺序

## 第 1 个 Commit：Baseline

```text
test: add xxx regression baseline
```

---

## 第 2 个 Commit：Pure Extraction

```text
refactor: extract xxx coordinator
```

只移动实现，不改行为。

---

## 第 3 个 Commit：Dependency Boundary

```text
refactor: narrow xxx module dependencies
```

---

## 第 4 个 Commit：Canonical API

```text
feat: add canonical xxx API
```

---

## 第 5 个 Commit：Compatibility

```text
refactor: forward legacy xxx API to canonical implementation
```

---

## 第 6 个 Commit：Tests / Docs

```text
test: cover xxx migration
docs: update xxx roadmap
```

---

## 禁止一个 Commit 同时

```text
移动几十个文件
+
升级第三方
+
改 API
+
改业务逻辑
+
改 podspec
+
改 Package.swift
```

否则 bisect 很困难。

---

# 31. 每个版本统一 Definition of Done

## Code

- [ ] `git diff --check`
- [ ] Swift 6 compile。
- [ ] 无新增未登记 unsafe concurrency。
- [ ] 无意外 public API 删除。
- [ ] 无新的反向依赖。

## Package

- [ ] `swift package dump-package`
- [ ] SPM target build。
- [ ] Podspec lint。
- [ ] SPM/Pods parity。

## Runtime

- [ ] Example run。
- [ ] iOS 17。
- [ ] iOS 26。
- [ ] Light/Dark。
- [ ] Rotation。
- [ ] Memory warning。
- [ ] Background/Foreground。

## Docs

- [ ] CHANGELOG。
- [ ] ROADMAP。
- [ ] RELEASE。
- [ ] MIGRATION。
- [ ] README（如果 API 有变化）。

---

# 32. 最推荐的实际执行顺序

如果你自己逐项修改，建议严格按下面做：

```text
5.7.9
│
├─ 版本/文档基线纠偏
├─ Alert 当前修复回归
└─ 生成 architecture baseline

5.8.0
│
├─ SPM dependency graph
├─ CocoaPods graph
└─ parity / dependency direction gate

5.8.1
│
├─ PToolsCore
├─ PToolsUIFoundation
└─ ptools umbrella

5.8.2
│
├─ PermissionCore
├─ PermissionUI
└─ permission target 最小依赖

5.8.3
│
└─ Network

5.8.4
│
└─ PTCollectionView internal coordinators

5.8.5
│
├─ NavigationDelegateProxy
├─ BaseVC 瘦身
└─ TabBar navigation coordination

5.8.6
│
├─ Theme
├─ Appearance
└─ PTTabBarView

5.8.7
│
└─ Media inversion

5.8.8
│
└─ Debug / Logger / Swizzle isolation

5.8.9
│
└─ 架构稳定回归

5.9.0
│
└─ Canonical API freeze

5.9.1
│
└─ Swift 6 final audit

5.9.2
│
└─ Tests / Benchmark

5.9.3
│
└─ Scene / lifecycle / singleton scope

5.9.4
│
└─ Performance / memory / cache

5.9.5
│
└─ Accessibility / iOS 26

5.9.6
│
└─ Third-party supply chain

5.9.7
│
└─ Docs / Example / MIGRATION_6

5.9.8
│
└─ Feature Freeze + 6.0 rehearsal

5.9.9
│
└─ Final 5.x stable baseline

6.0
│
└─ 删除已经完整迁移的 legacy API
```

---

# 33. 优先级

## P0：必须在 6.0 前完成

1. Core Dependency Diet。
2. SPM / CocoaPods parity。
3. PermissionCore 去 UI。
4. Network mutable/shared concurrency。
5. Navigation delegate ownership。
6. PTCollectionView internal split。
7. API migration inventory。
8. Third-party build blockers。
9. 6.0 rehearsal。

---

## P1：强烈建议

1. Theme / Appearance。
2. Media Network decoupling。
3. Debug isolation。
4. Scene scope。
5. Benchmark。
6. Public API baseline。
7. Cache inventory。

---

## P2：可以跟随业务需求

1. 进一步减少第三方库。
2. 更彻底的命名统一。
3. 所有组件完全 DI。
4. Core 第三方依赖归零。
5. 更复杂的插件化架构。

不要因为追求“教科书架构”而推迟发布。

---

# 34. 最终判断

PTools 当前已经不属于“缺功能”的阶段。

下一阶段最应该解决的是：

```text
现在：
很多模块
   ↓
都依赖 ptools
   ↓
ptools 又依赖大量第三方和高层 UI 能力

目标：
功能模块
   ↓
只依赖最小 Foundation / UI / Protocol
   ↓
具体三方实现成为 Adapter
```

以及：

```text
现在：
PTCollectionView / BaseVC / Network / TabBar
本身越来越像子框架

目标：
外部 API 保持简单
内部 Coordinator / Provider / Adapter 化
```

如果严格按照这份路线执行，5.9.9 应该成为一个：

> **公开 API 仍兼容 5.x，但内部结构已经基本达到 6.0 形态的版本。**

那么 6.0 的工作就不再是“大规模重写”，而只是：

```text
删除 legacy
统一命名
收紧模块边界
正式切换新的 product
更新 migration
```

这才是风险最低的 Major Version 升级方式。

---

# 35. 仓库审查参考点

本路线图制定时重点核对：

```text
master commit:
d044b657a8db4e94052916cd7ffc9b0f5b749594

PooTools.podspec
Package.swift
ROADMAP_5X.md
MIGRATION_5X.md
RELEASE.md
README.md

PooToolsSource/Base/PTCollectionView.swift
PooToolsSource/Base/PTBaseViewController.swift
PooToolsSource/Base/PTTabBarView.swift
PooToolsSource/Base/PTAppBaseConfig.swift
PooToolsSource/NetWork/Network.swift

PooToolsSource/Core/
PooToolsSource/Base/
PooToolsSource/PermissionCore/
PooToolsSource/MediaViewer/
```

后续每完成一个版本，都建议重新生成依赖和架构 baseline，而不是继续依赖本文件中的旧统计数字。

---

# 36. 可直接复制到 GitHub Project 的 Milestone

## Milestone: 5.7.9 Stable Baseline

- [x] REL-579-01 Metadata sync（Git tag 仍待构建门禁通过）
- [ ] REL-579-02 Alert regression（源码顺序已确认，人工视觉回归待构建恢复）
- [x] REL-579-03 Architecture baseline
- [ ] REL-579-04 Full build matrix（外部 `KituraContracts` 阻断）

## Milestone: 5.8.0 Dependency Contract

- [x] DEP-580-01 SPM graph
- [x] DEP-580-02 Pod graph
- [x] DEP-580-03 Parity gate
- [x] DEP-580-04 Dependency budget
- [x] DEP-580-05 Direction gate

## Milestone: 5.8.1 Core Split

- [ ] CORE-581-01 PToolsCore
- [ ] CORE-581-02 UIFoundation
- [x] CORE-581-03 Core file classification
- [x] CORE-581-04 Legacy forwarding
- [ ] CORE-581-05 Umbrella compatibility

## Milestone: 5.8.2 Permission

- [ ] PERM-582-01 PermissionCore
- [ ] PERM-582-02 PermissionUI
- [ ] PERM-582-03 Minimal targets
- [x] PERM-582-04 Async API
- [ ] PERM-582-05 System service separation

## Milestone: 5.8.3 Network

- [ ] NET-583-01 Immutable configuration
- [x] NET-583-02 Request environment（兼容切片；完整 adapter 分离仍待完成）
- [ ] NET-583-03 Plugin registry
- [ ] NET-583-04 Instance network
- [ ] NET-583-05 Unified pipeline
- [ ] NET-583-06 HUD plugin
- [x] NET-583-07 Retry snapshot
- [x] NET-583-08 Download instance isolation
- [x] NET-583-09 Sendable audit
- [ ] NET-583-10 Tests

## Milestone: 5.8.4 List

- [x] LIST-584-01 Data coordinator
- [ ] LIST-584-02 Layout provider
- [x] LIST-584-03 Photo prefetch（资源去重、引用计数取消和生命周期清理兼容切片）
- [ ] LIST-584-04 Skeleton
- [ ] LIST-584-05 Interaction
- [ ] LIST-584-06 Refresh
- [ ] LIST-584-07 Side index
- [ ] LIST-584-08 Scroll observer
- [x] LIST-584-09 LRU cache extraction
- [x] LIST-584-10 LOC gate

## Milestone: 5.8.5 Navigation

- [x] NAV-585-01 Delegate proxy
- [ ] NAV-585-02 Manager observer
- [x] NAV-585-03 Host forwarding
- [ ] NAV-585-04 Stack isolation
- [ ] NAV-585-05 BaseVC slimming
- [x] NAV-585-06 UIScrollView appearance
- [ ] NAV-585-07 Transition matrix

## Milestone: 5.8.6 Theme

- [x] THEME-586-01 Appearance structs
- [x] THEME-586-02 PTTheme
- [x] THEME-586-03 BaseConfig compatibility（legacyDefault 兼容切片）
- [x] THEME-586-04 Snapshot semantics（TabBar 外观快照兼容切片）
- [ ] TAB-586-05 TabBar internals
- [ ] TAB-586-06 Lottie adapter
- [x] TAB-586-07 Visual style enum

## Milestone: 5.8.7 Media

- [x] MEDIA-587-01 Resource model
- [x] MEDIA-587-02 Image loader
- [ ] MEDIA-587-03 MediaViewer decouple
- [ ] MEDIA-587-04 PhotoPicker decouple
- [x] MEDIA-587-05 Video provider/cache
- [ ] MEDIA-587-06 Lifecycle
- [ ] MEDIA-587-07 Editor dependencies

## Milestone: 5.8.8 Diagnostics

- [x] DEBUG-588-01 Logging protocol
- [ ] DEBUG-588-02 Logger adapter
- [ ] DEBUG-588-03 Production isolation
- [x] DEBUG-588-04 Swizzle registry
- [ ] DEBUG-588-05 Scene scope

## Milestone: 5.8.9 Stabilization

- [x] Architecture report
- [x] Dependency report
- [x] API report
- [x] Performance report
- [ ] Real app regression

## Milestone: 5.9.0 API Freeze

- [x] API-590-01 Canonical inventory
- [x] API-590-02 Typo aliases
- [x] API-590-03 Thin wrappers
- [x] API-590-04 Public API baseline

## Milestone: 5.9.1 Concurrency

- [x] CONC-591-01 Global scan
- [x] CONC-591-02 UI MainActor（Core 高频 UIKit 边界）
- [x] CONC-591-03 Service isolation（Network、请求去重、媒体缓存）
- [x] CONC-591-04 Sendable snapshots
- [x] CONC-591-05 Cancellation（底层取消桥接已落地，真实宿主回归待验证）

## Milestone: 5.9.2 Quality

- [x] TEST-592-01 Test targets
- [x] TEST-592-02 Collection benchmark
- [x] TEST-592-03 Network benchmark
- [x] TEST-592-04 Media benchmark
- [x] TEST-592-05 Navigation harness

## Milestone: 5.9.3 Lifecycle

- [x] LIFE-593-01 Window API cleanup
- [x] LIFE-593-02 Scene UI state
- [x] LIFE-593-03 Singleton classification
- [x] LIFE-593-04 DI entry points

## Milestone: 5.9.4 Performance

- [x] PERF-594-01 Cache inventory
- [x] PERF-594-02 MainActor heavy work
- [x] PERF-594-03 Layout duplicate work
- [x] PERF-594-04 Memory warning

## Milestone: 5.9.5 UI Quality

- [x] UI-595-01 Dynamic Type
- [x] UI-595-02 Reduce Motion
- [x] UI-595-03 Reduce Transparency
- [x] UI-595-04 Visual style strategy

## Milestone: 5.9.6 Dependencies

- [x] DEP-596-01 Branch dependencies（AttributedString、SocketRocket 固定 revision）
- [x] DEP-596-02 Kitura review（保留 Swift-JWT，移除 PTools 未直接使用的重复声明）
- [x] DEP-596-03 Codable stack（SmartCodable 主入口，KakaJSON 兼容边界）
- [x] DEP-596-04 Binary framework（示例工程移除旧 Bugly 硬依赖，改为 XCFramework 可选接入）
- [x] DEP-596-05 Dependency ownership（补齐 `DEPENDENCIES.md` 和专项报告）

## Milestone: 5.9.7 Migration

- [x] DOC-597-01 README module sets
- [x] DOC-597-02 Dependency docs
- [x] DOC-597-03 Example pages index and module regression guide
- [x] DOC-597-04 MIGRATION_6

## Milestone: 5.9.8 6.0 Rehearsal

- [ ] Feature freeze
- [ ] release/6.0-rehearsal
- [ ] Delete deprecated
- [ ] PTools Example migration
- [ ] CrazyDashboard migration
- [ ] Real business app migration

## Milestone: 5.9.9 Final 5.x

- [ ] Full regression
- [ ] Full build matrix
- [ ] Freeze module graph
- [ ] Freeze public API
- [ ] Freeze deletion list
- [ ] Freeze migration guide
- [ ] Tag 5.9.9

---

## 5.9.x 当前实施记录（2026-09-10）

以下状态只反映本次工作树已经落地的内容；“已建立”不等于 Xcode、真机或真实宿主项目
已经通过。所有未完成项保留为待验证或外部阻断，不提前标记完成。

### 已落地

- [x] API-590-01 / API-590-03：新增 MIGRATION_6.md，并将正确命名入口与旧兼容转发登记。
- [x] API-590-02：完成 globalURL、socketGlobalURL、globalNavControl、webImageLoadOptions、
  highlightColor 和 PTNetworkConfig 正确命名入口。
- [x] API-590-04：生成 PUBLIC_API_5_9.json，并提供与 5.8 基线的删除差异检查。
- [x] CONC-591-01：生成全仓 Swift 6 并发敏感操作报告；未新增 nonisolated(unsafe)。
- [x] CONC-591-02：为 PTBaseViewController、PTBaseNavControl、PTBaseTabBarViewController、
  PTTabBarView、Cell/Mask/Button/Navigation 容器和 PTUpdateTipsContentView 建立 MainActor 边界。
- [x] CONC-591-03：RequestDeduplicator 改为 actor；Network Session 初始化、插件和配置访问加锁；
  NetworkCache、PTVideoCoverDiskStore 使用 actor/不可变状态；视频封面共享任务只在最后一个等待者取消时停止。
- [x] CONC-591-04：PTProgressSnapshot、PTResponseMetadata 和网络响应快照只传递 Sendable 值；
  PhotoKit 请求状态使用锁保护，UIImage 留在 MainActor；PTTimeUtils 移除共享可变 DateFormatter，
  PTProgressSnapshot 与 PTResponseMetadata 保持 Equatable 契约。
- [x] CONC-591-05：Task 取消已桥接到 GCD continuation、Alamofire 下载/上传请求、PhotoKit 请求、
  AVAsset 导出和视频缩略图生成；共享请求采用等待者计数，避免单个调用方取消误伤其他调用方。
- [x] TEST-592-01：增加 SwiftPM PToolsCoreTests 契约测试目标，移除 Xcode scheme 中不存在的旧测试引用。
- [x] TEST-592-01：扩展为 7 个 iOS-only SwiftPM 测试目标，覆盖 Core、UI、Network、List、Navigation、Media 和 Permission。
- [x] TEST-592-02：增加 1k/10k 全量快照、增量追加、稳定 ID 快速更新和 Collection 场景清单基准夹具。
- [x] TEST-592-03：增加稳定请求键、100 并发相同请求去重和请求键构造基准；真实网络 cache/retry/下载/取消保留宿主回归。
- [x] TEST-592-04：增加视频帧请求、封面键、无效视频和 4K 缩略图准备基准夹具。
- [x] TEST-592-05：增加 push/pop、多导航容器、interactive-pop 入口、宿主 delegate 和 TabBar 标记回归 harness。
- [x] 生成 `report/quality_5_9_2.md`，并将 5.9.2 的静态建立状态与 Xcode/真机待验证状态分开记录。
- [x] LIFE-593-04：增加 PTSceneContextProviding 和默认场景解析提供器。
- [x] LIFE-593-01：统一 PTSceneContext 的场景、窗口和当前控制器解析；移除生产路径中的
  `connectedScenes.first`、`delegate.window` 和直接全局窗口查询。保留 `UIApplication.override(_:)`
  对所有已连接场景逐一应用样式的兼容行为。
- [x] LIFE-593-02：Alert 状态改用持久化场景标识保存，控制台支持按场景创建窗口和控制台实例，
  调试标尺、取色器、启动看板、HUD、旋转回调和导航转场进度都优先使用宿主场景或导航栈。
- [x] LIFE-593-03：升级 `report_singletons_5_9.rb`，同时盘点 `.shared` / `.share`，按 A/B/C/D
  输出分类、作用和迁移建议，并增加生命周期门禁校验所有声明都已分类。
- [x] LIFE-593-04：保留现有 `PTSceneContextProviding` 注入入口，并增加 `LocalConsole.console(for:)`
  和调试组件的显式场景入口，兼容旧的 shared/share 调用。
- [x] LIFE-593：生成 `report/build_validation_5_9_3.md`，记录静态门禁结果、Xcode Debug / Release
  外部 KituraContracts 阻断，以及仍需真实宿主执行的多 Scene 生命周期回归。
- [x] PERF-594-01：生成缓存盘点报告，并为 NetworkCache、PTVideoCoverCache、PTAudioService 和列表布局缓存设置容量或成本边界。
- [x] PERF-594-02：完成 MainActor 重任务代码审查；图片/GIF、视频缩略图和网络缓存维护不在 UI 回调中同步解码大数据，UI 结果仍回到 MainActor。
- [x] PERF-594-03：为 PTNavBar 增加几何签名缓存，避免重复重建标题约束；PTTabBarView 只在遮罩几何变化时更新图层，并避免布局回调中的重复 layoutIfNeeded。
- [x] PERF-594-04：新增 PTMemoryWarningCoordinator；PTCollectionView、PTVideoCoverCache 和 PTAudioService 响应内存告警，释放派生缓存并取消未完成的视频封面任务。
- [x] UI-595-01：Alert、TabBar、NavigationBar、Picker、Permission、Collection index 和 ImageEditor 高频文本入口接入 Dynamic Type。
- [x] UI-595-02：Banner 自动轮播、TabBar Lottie、Picker 过渡、Blur 动画和 Sheet 动画尊重 Reduce Motion，并在系统设置变化后即时刷新。
- [x] UI-595-03：新增 Core 级视觉策略解析器；Blur、TabBar、Picker、Alert、Sheet 和 Navigation 在 Reduce Transparency 时切换动态不透明背景，并支持设置变化后即时重绘。
- [x] UI-595-04：新增 `PTVisualStyle`（`automatic` / `classic` / `material` / `glass`）和 `PTVisualStyleResolver`，避免 iOS 26 系统效果判断散落在各模块。
- [x] UI-595：刷新 `report/accessibility_5_9.{json,md}`；代码门禁完成，真实设备/宿主界面回归仍是发布前置条件。
- [x] DEP-596-01：固定 AttributedString、SocketRocket revision，并由 `validate_dependencies_5_9_6.sh` 门禁校验。
- [x] DEP-596-02：确认 CheckUpdate 仅直接使用 Swift-JWT；移除 Package.swift 中未被 PTools 直接使用的 Kitura/LoggerAPI 重复声明，CryptoKit/Security 替换延后到 6.0。
- [x] DEP-596-03：确认 SmartCodable 为主要模型入口，KakaJSON 仅保留现有兼容边界，记录 Serialization 拆分条件。
- [x] DEP-596-04：移除 Example 的旧 Bugly Pod 和 lock 条目；AppDelegate 保留 `canImport(Bugly)` 兼容入口，宿主项目重新接入时必须提供 XCFramework。
- [x] DEP-596-05：更新 `DEPENDENCIES.md`，新增 `report/dependency_supply_chain_5_9_6.md`。
- [x] 5.9.6 Xcode 验证：Debug / Release 均已执行；结果受外部 KituraContracts Swift 6 诊断阻断，详见 `report/build_validation_5_9_6.md`。
- [x] DOC-597-01 / DOC-597-02 / DOC-597-04：更新 README、RELEASE、CHANGELOG、依赖文档并补齐迁移配方。
- [x] DOC-597-03：新增 `EXAMPLE_MODULES_5_9.md`，登记 `PooTools-Example` 的真实页面入口、模块覆盖和回归清单；真实宿主项目迁移继续留到 5.9.8 rehearsal。
- [x] 新增 5.9.x 验证脚本：API、并发、单例、缓存、无障碍、依赖分支和迁移门禁。
- [x] 记录当前 Xcode Debug / Release 和直接 PooTools scheme 构建结果：`report/build_validation_5_9.md`。
- [x] 2026-09-10 兼容切片：`PTTabBarView` 外观快照、`PTCollectionPhotoPrefetchCoordinator` 预取引用计数与生命周期清理、Network 实例请求环境/Typed Codable 入口，以及稳定 request/cache key；旧公开入口均保留。

### 待验证或阻断

- [ ] 本次源码修改后的 Xcode Debug / Release 仍被外部 `Pods/KituraContracts` 的 Swift 6 并发诊断阻断；详见 `report/build_validation_5_9_5_current.md`。
- [ ] 5.9.1 Xcode Debug / Release 完整构建和真实宿主回归：当前被外部 KituraContracts、
  swift-syntax 网络获取和工具链环境阻断；需解除阻断后再完成最终验收。
- [ ] TEST-592-02 至 TEST-592-05：Xcode iOS Simulator、真实宿主、真机和 Instruments 的实际执行结果；静态夹具已建立但不等于性能验收。
- [ ] LIFE-593-01 至 LIFE-593-03：多窗口、多 Scene、Scene 断开重连和并行转场的真实宿主回归；静态门禁已完成。
- [ ] PERF-594-02 至 PERF-594-04：代码实现已完成，仍需在可运行的 Xcode 宿主、真机和 Instruments 中完成性能基线与内存告警实测。
- [ ] 宿主项目若重新接入 Bugly，仍需供应商 XCFramework、Simulator slice、通用 device archive 和真实宿主归档验证。
- [ ] 真实宿主项目迁移：需要 CrazyDashboard 和其他宿主项目在 5.9.8 rehearsal 中单独执行。
- [ ] 5.9.8 / 5.9.9：6.0 rehearsal、完整 Xcode 矩阵、真机/宿主回归和最终 tag。

已知外部阻断：Metal 工具链和部分 Kitura/Pods Swift 6 诊断。宿主重新接入旧版
Bugly 时还会重新引入二进制架构阻断。阻断解除前不得宣称 5.9.x 完整验收通过或创建发布标签。
