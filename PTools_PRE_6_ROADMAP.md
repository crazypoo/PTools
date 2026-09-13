# PTools 6.0 之前完整升级与架构优化路线图

> 项目：PTools / PooTools
> 仓库：`https://github.com/crazypoo/PTools`
> 路线图制定日期：2026-09-08
> 本次路线图更新：2026-09-13（完成 5.11.x PTInstruments 实现切片并记录运行时待验证项）
> 审查基线：`master` @ `a5030237`（2026-09-10）
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
9. **5.10.x 完成 Debug 经典模块的正式解耦、Foundation 化和 Scene/Window 稳定化。**
10. **5.11.x 完成 PTInstruments、Session、Timeline 与可导出运行时诊断链路。**

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

Debug / Diagnostics 作为上层一等模块，而不是塞回 Core：

```text
                     PooToolsDEBUG
                          │
          ┌───────────────┼────────────────┐
          ▼               ▼                ▼
   Debug Foundation    Collectors      Debug UI
          │               │                │
          └───────────────┼────────────────┘
                          ▼
                    PTInstruments
                          │
                          ▼
              Session / Timeline / Export

依赖：PooToolsDEBUG -> Core / UIFoundation / 可选功能适配器
禁止：Core -> PooToolsDEBUG
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

**Quality / Readiness Foundation Series**

5.9.x 不再定义为“最终 5.x”或“Feature Freeze”。在 5.10.x / 5.11.x 已确定继续演进 Debug 的前提下，5.9.x 的职责调整为：先把全仓 API、并发、测试、生命周期、性能、依赖供应链和迁移文档做成可信基线。

目标：

```text
冻结 canonical API 的基本方向
收口 Swift 6
建立测试和 benchmark
清理依赖供应链
建立 Scene / Lifecycle / Performance 基线
为 5.10.x Debug Foundation 提供稳定底座
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
5.9.8 Pre-Debug Architecture Validation
5.9.9 Pre-Debug Stable Baseline
```

---

## 5.10.x

**Debug Decoupling & Foundation Series**

定位：Debug 是 PTools 的经典核心调试模块和一等能力，但依赖架构仍必须保持单向：

```text
PToolsCore / ptools
        ↑
        │
   PooToolsDEBUG
```

Debug 可以依赖 Core；Core 不允许认识 `LocalConsole`、Inspector、Debug Window、Debug 配置或任何 Debug UI。5.10.x 的重点是建立稳定边界和可复用采集基础，不追求 Instruments UI。

推荐版本：

```text
5.10.0 Core / Debug Dependency Audit & Contract
5.10.1 Debug Preferences / Configuration Migration
5.10.2 Logging Decoupling & Debug Log Sink
5.10.3 PTDebugManager / Plugin / Event Foundation
5.10.4 LocalConsole Responsibility Split
5.10.5 Debug Window / Scene Stabilization
5.10.6 Network / Lifecycle / Log Collector Migration
5.10.7 Crash / Leak / Inspector / MockLocation Migration
5.10.8 Compatibility / Regression / Overhead Audit
5.10.9 Debug Foundation Stable Baseline
```

---

## 5.11.x

**PTInstruments & Runtime Diagnostics Series**

5.11.x 在 5.10.x Debug Foundation 上增加统一运行时诊断能力。目标不是复制完整 Xcode Instruments，而是在 App 内提供可录制、可关联、可导出的性能与调试时间线。

推荐版本：

```text
5.11.0 PTInstruments Core / Session / Recorder
5.11.1 FPS / Frame Time / Hitch Instruments
5.11.2 CPU / Memory / Main Thread Stall Instruments
5.11.3 Network / Lifecycle / Log / Leak Tracks
5.11.4 Timeline Model / Storage / Sampling Policy
5.11.5 Timeline UI / Track Rendering / Zoom & Selection
5.11.6 Event Inspector / Filter / Correlation
5.11.7 Custom Trace / Export / Import (.pttrace)
5.11.8 Overhead / Privacy / Real-App Regression
5.11.9 Final 5.x Debug & Diagnostics Baseline + 6.0 Rehearsal
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
5.11.x 结束：<= 3
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

## 5.8.1–5.8.9 当前实施状态（2026-09-10）

本批按“可独立回滚、可验证、保持兼容”的原则落地了安全切片。以下勾选仅表示对应切片已经实现，不代表尚未完成的独立 Target 拆分或真实设备回归已经完成。

### 5.8.1 Core / UIFoundation

- [x] `CORE-581-01`：新增可独立编译的 Foundation-only `PToolsCore` SwiftPM target，承载 URL 解析、值类型和关联对象存储。
- [x] `CORE-581-02`：新增 `PToolsUIFoundation` SwiftPM target，独立承载 SnapKit 布局辅助。
- [x] `CORE-581-03`：完成 Core 文件分类；旧 Xcode/CocoaPods 源集保留兼容实现。
- [x] `CORE-581-04`：完成 URL 解析迁移和 Base 控制器弃用转发。
- [x] `CORE-581-05`：`ptools` 依赖并 re-export 两个基础分层，`import ptools` 保持兼容；CocoaPods/Xcode 的独立 framework membership 延后迁移。

### 5.8.2 Permission

- [x] `PERM-582-01`：新增 Foundation-only `PToolsPermissionCore`，并在 SwiftPM `ptools` 兼容入口中映射旧 `PTPermission` 类型名。
- [ ] `PERM-582-02`：新增可选 `PToolsPermissionUI` 状态模型和设置页桥接；旧 PermissionCore UIKit 类型的完整迁移仍待 UI 基座独立后处理。
- [x] `PERM-582-03`：Camera、Location、Calendar、Motion、Tracking、Reminders、Speech、Health、FaceID、Contacts、Mic、Media、Bluetooth、Siri 和 Notification SwiftPM target 改为直接依赖 `PToolsPermissionCore`；PhotoLibrary 因已属于 Core 兼容源集，不重复声明同路径 target。
- [x] `PERM-582-04`：补充 `currentStatus()`、`requestStatus()`、`openSettings()`，并用 exactly-once 桥接保证回调只恢复一次。
- [ ] `PERM-582-05`：Location handler 和 Bluetooth handler 已独立处理系统代理生命周期；Motion/Speech 等系统服务的统一 protocol 和 CocoaPods/Xcode framework 拆分仍待后续垂直切片。

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

- [x] `PToolsCore` 可单独 build。
- [x] `PToolsCore` 不依赖 UIKit feature。
- [x] `PToolsUIFoundation` 可单独 build。
- [x] 旧 `import ptools` 的 Xcode/CocoaPods 源码分支保持不变，兼容实现继续保留。
- [x] 新分层的第三方依赖边界明确：`PToolsCore` 为零，`PToolsUIFoundation` 仅使用 SnapKit。
- [x] source contract 增加 SwiftPM Core / UIFoundation target 检查。

### 5.8.1 本次实施边界（2026-09-10）

- SwiftPM 已提供 `PToolsCore`、`PToolsUIFoundation` 两个可独立编译的 target，`ptools` 依赖并重新导出它们。
- Xcode/CocoaPods 继续编译旧兼容源集，通过条件编译保留 `PTURLParser`、值类型、关联对象和 SnapKit 辅助能力，避免宿主工程被迫改 import。
- Example Xcode Debug/Release 构建仍需在外部 `Pods/KituraContracts` Swift 6 阻断解决后完成；该阻断不归因于本次 PTools 源码改动。

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

- [x] 单独引入 CameraPermission 不引入 Kingfisher/Lottie/Network；契约脚本会阻断 umbrella/UI/network import。
- [x] 所有独立 SwiftPM 权限 target 已通过 iOS Simulator / Swift 6 直接源码编译；PhotoLibrary Core 兼容源也通过同一编译路径，完整 SwiftPM 图和 Xcode 工程构建仍按外部依赖结果单独记录。
- [x] 权限 UI 可选；`PToolsPermissionUI` 不依赖 `ptools`，旧 UIKit UI 继续由兼容 umbrella 提供。
- [x] async / callback exactly-once；Core continuation、Location delegate 和 Bluetooth delegate 均有重复完成保护。
- [x] permission manager 的 Location/Bluetooth delegate 在完成请求前解除；系统 delegate 为弱引用。
- [x] 各具体权限实现已统一映射 authorized、denied/restricted、notDetermined 和 unknown 状态；真机弹窗行为仍需宿主回归。

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

# 13. 5.8.8：Debug / Logging / Runtime Isolation（前置基础）

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

> 本节只建立 5.10.x 的前置契约与隔离基础；完整的 Core / Debug 语义解耦、LocalConsole 拆责和 Debug Foundation 统一迁移放到 5.10.x。


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

# 23. 5.9.8：Pre-Debug Architecture Validation

5.9.8 不再执行全仓 Feature Freeze，也不提前删除 6.0 deprecated API。它负责验证 5.9.0～5.9.7 建立的 API、并发、测试、生命周期、性能和依赖基线，确保 5.10.x 可以在稳定底座上重构 Debug。

## 允许

- [ ] Bug fix。
- [ ] Security。
- [ ] Performance。
- [ ] Accessibility。
- [ ] Migration。
- [ ] Tests。
- [ ] Dependency cleanup。
- [ ] Build fix。
- [ ] 为 5.10.x Debug 解耦补充必要的非破坏性契约。

## 禁止

- [ ] 在 Core 新增 Debug 专属状态。
- [ ] 新增 Core → Debug 类型引用。
- [ ] 新增无法被 5.10.x Plugin / Event Foundation 接管的 Debug 全局单例。
- [ ] 提前删除尚未经过迁移周期的 public API。

## VAL-598-01 Debug 前置依赖审计

至少输出：

```text
Core -> Debug direct symbol references
Core 中 Debug-specific UserDefaults keys
Core 中 Debug menu / runtime special cases
LocalConsole responsibilities inventory
Debug swizzle owners
Debug Window / Scene ownership
PooToolsDEBUG -> Core / Network / Share / SearchBar / PDF dependencies
```

## VAL-598-02 真实 App 验证

至少：

```text
PTools Example
CrazyDashboard
另一个真实业务 App
```

本阶段只记录迁移风险，不执行 6.0 删除。

---

# 24. 5.9.9：Pre-Debug Stable Baseline

5.9.9 是进入 5.10.x 前的稳定基线，不再定义为“最终 5.x”。

## 5.9.9 冻结以下基线

- [ ] 5.10.x 开始前的 Module graph。
- [ ] Canonical API baseline。
- [ ] Public API baseline。
- [ ] Sendable exception list。
- [ ] Performance baseline。
- [ ] SPM / CocoaPods parity。
- [ ] iOS 17 / iOS 26 regression matrix。
- [ ] Debug dependency audit baseline。

要求：

```text
5.9.9 可以继续被业务项目使用
5.10.x Debug 内部重构不要求宿主立刻迁移
旧 LocalConsole / Debug 公开入口必须有兼容策略
```

---

# 25. 5.10.x：Debug Decoupling & Foundation

## 25.1 定位与不可破坏原则

Debug 是 PTools 的经典核心调试模块，不按“可有可无的附属工具”处理。5.10.x 的目标不是削弱 Debug，而是把它正式提升为边界清晰的一等模块。

依赖必须保持：

```text
PToolsCore / ptools
        ↑
        │
   PooToolsDEBUG
```

必须满足：

```text
Core 单独安装 / 编译时不需要 Debug
Debug 安装后可以完整使用 Core
移除 Debug 不要求修改 Core 源码
Core 不直接引用 LocalConsole / PTLogLevel / Inspector / DebugWindow / Debug Configuration
```

5.x 继续兼容经典入口，例如 `LocalConsole.shared`。内部可以改为 Compatibility Layer 转发，但不应为了重构强迫宿主项目一次性迁移。

## 25.2 当前已知解耦重点

结合当前仓库审查，5.10.x 首批治理点至少包含：

### DEBUG-5100-01 `PTNSLog` 不直接认识 `LocalConsole`

当前 Core 日志路径即使受 `POOTOOLS_DEBUG` 条件编译保护，只要源码直接引用 Debug 类型，仍属于反向耦合。

目标：

```text
PTNSLog / PTLogging / PTLogEvent
            ↓
        Log Contract
            ↑
            │
      PTDebugLogSink
            ↓
       LocalConsole
```

要求：

- [ ] Core Logger 不 import / 不引用 Debug 类型。
- [ ] Console 仍可实时接收 Core 日志。
- [ ] Instruments Session 后续可复用同一日志事件，不重复 hook。

### DEBUG-5100-02 Debug Preferences 从 Core 迁出

从 `PTCoreUserDefultsWrapper` 等 Core 状态中迁出 Debug 专属配置，例如：

```text
AppDebugMode
DevMask / TouchBubble
TouchInspector / Hits
LocalConsole font / frame / x / y
MockLocation open / latitude / longitude
```

目标：

```text
PTDebugConfiguration
        ↓
PTDebugPreferences
        ↓
UserDefaults
```

旧 key 必须支持无损迁移，不能造成用户已有 Debug 配置全部丢失。

### DEBUG-5100-03 Core Runtime 不特判 Debug UI 语义

Core 中对 `"Debug"`、`"UserDefaults"` 等 Debug 菜单标题或 Debug UI 状态的特殊判断迁入 Debug adapter / category。

原则：

```text
Core 提供通用 runtime capability
Debug 决定如何使用 capability
```

## 25.3 Debug Foundation

建立稳定的内部基础层：

```text
PooToolsDEBUG
│
├── Foundation
│   ├── PTDebugManager
│   ├── PTDebugPlugin
│   ├── PTDebugCollector
│   ├── PTDebugEvent
│   ├── PTDebugEventCenter
│   ├── PTDebugConfiguration
│   └── PTDebugPreferences
│
├── Collectors
├── Console
├── Inspector
├── Network
├── Lifecycle
├── Crash
├── Leak
├── MockLocation
└── UI
```

建议协议：

```swift
public protocol PTDebugPlugin: AnyObject {
    var identifier: String { get }
    var isRunning: Bool { get }
    func start()
    func stop()
}
```

`PTDebugManager` 只负责：

```text
register
start / stop
plugin lifecycle
configuration
session coordination entry
```

禁止把每个 Debug 工具的业务继续堆进新的巨型 Manager。

## 25.4 LocalConsole 拆责

`LocalConsole` 回归 Console 本身，不继续承担整个 Debug subsystem 的 bootstrap。

逐步迁出：

```text
URLSession swizzle -> PTNetworkCollector
UIViewController lifecycle swizzle -> PTLifecycleCollector
Crash -> PTCrashCollector
Leak -> PTLeakCollector
Inspector -> PTInspectorPlugin
Mock Location -> PTMockLocationPlugin
stdout / stderr -> PTConsoleCollector
Debug Window -> PTDebugWindowCoordinator
```

保留：

```text
LocalConsole.shared
LocalConsole.console(for:)
show / hide / print 等经典公开入口
```

内部转发到新 Foundation。

## 25.5 Event / Collector 单向数据流

Debug UI 不直接从各 Monitor 拉取内部状态。统一：

```text
Collector / Plugin
      ↓
 PTDebugEvent
      ↓
PTDebugEventCenter
      ↓
┌───────────┬───────────┬───────────┐
Console   Storage     Session     Dashboard
```

这样 5.11.x `PTInstruments` 只需要消费事件和采样，不需要重新实现一套 Network / Lifecycle / Leak 监听。

## 25.6 Window / Scene 稳定化

在现有 `LocalConsole.console(for:)` 和 Scene Scope 基础上继续完成：

- [ ] Debug Window 按 `UIWindowScene` 隔离。
- [ ] 不使用单一全局 Debug Window 覆盖所有 Scene。
- [ ] `windowLevel` 不破坏业务 present / sheet。
- [ ] hitTest 穿透只作用于明确的非交互区域。
- [ ] close / reopen 生命周期稳定。
- [ ] 键盘、安全区、刘海、横竖屏、分屏稳定。
- [ ] Scene disconnect 时彻底释放 Window / observer / display link。
- [ ] 多 Scene 同时开启 Debug 时状态互不污染。

## 25.7 Swizzle 生命周期

复用 `PTSwizzleRegistry`，每个 Debug hook 必须登记 owner。

要求：

```text
同一 selector 不重复 swizzle
插件重复 start 不重复安装
stop / scene disconnect 有明确清理语义
无法 undo 的 swizzle 必须登记原因
Debug 禁用后不继续产生高频事件
```

## 25.8 推荐版本切片

```text
5.10.0 依赖审计 / Contract Gate
5.10.1 Debug Preferences / Configuration
5.10.2 Logging / Log Sink
5.10.3 Debug Manager / Plugin / Event Foundation
5.10.4 LocalConsole 拆责
5.10.5 Window / Scene / Interaction 稳定化
5.10.6 Network / Lifecycle / Console Collectors
5.10.7 Crash / Leak / Inspector / MockLocation
5.10.8 Compatibility / Regression / Overhead
5.10.9 Stable Baseline
```

## 25.9 5.10.x 验收

- [ ] Core 源码扫描不存在 Debug 类型反向引用。
- [ ] Core Debug-specific preferences 清零或只保留真正通用 contract。
- [ ] `PTools/Core` / `PToolsCore` 可在不安装 DEBUG subspec/product 时独立工作。
- [ ] `PooToolsDEBUG` 继续完整依赖 Core，但不存在循环依赖。
- [ ] 经典 `LocalConsole` API 兼容。
- [ ] Network / Lifecycle / Crash / Leak / Inspector 不再由 LocalConsole 单例集中 bootstrap。
- [ ] Debug Window 多 Scene 回归通过。
- [ ] swizzle 重复安装测试通过。
- [ ] observer / Notification / DisplayLink / Timer 生命周期有测试或回归记录。
- [ ] Debug disabled 与 enabled 的性能差异建立 baseline。
- [ ] SPM / CocoaPods / Example 三入口一致。

建议输出：

```text
DEBUG_ARCHITECTURE_5_10.md
DEBUG_DEPENDENCY_GRAPH_5_10.md
DEBUG_PUBLIC_API_5_10.json
DEBUG_SWIZZLE_REGISTRY_5_10.md
DEBUG_SCENE_REGRESSION_5_10.md
DEBUG_OVERHEAD_BASELINE_5_10.md
```

---

# 26. 5.11.x：PTInstruments & Runtime Diagnostics

## 26.1 产品定位

`PTInstruments` 属于 `PooToolsDEBUG`，建立在 5.10.x Foundation / Collector / Event 之上。第一阶段目标是应用内诊断平台，而不是复制 Apple Instruments 的底层 profiler。

```text
Collectors
    ↓
PTDebugEventCenter / Samples
    ↓
PTInstrumentRecorder
    ↓
PTInstrumentSession
    ↓
Timeline / Inspector / Export
```

必须避免：

```text
PTInstruments 再 swizzle 一遍 URLSession
PTInstruments 再实现一套 Leak Detector
PTInstruments 再截获一套 VC Lifecycle
```

它应该复用 5.10.x 已有 Collector。

## 26.2 Instruments Core

建议类型：

```text
PTInstrument
PTInstrumentRecorder
PTInstrumentSession
PTInstrumentTrack
PTInstrumentSample
PTInstrumentEvent
PTInstrumentTimeline
PTInstrumentSamplingPolicy
```

Session 至少记录：

```text
id
startTime / endTime
app / device / OS metadata
selected instruments
events
samples
network summary
leak summary
performance summary
```

## 26.3 第一阶段 Instruments

### Performance

- [x] FPS。
- [x] Frame Time。
- [x] Hitch / Severe Hitch。
- [x] CPU。
- [x] Memory footprint / peak / growth。
- [x] Main Thread Stall。

FPS / Frame Time 必须根据实际 refresh rate 计算，不能硬编码 60 Hz / 16.67 ms。

Main Thread Stall 优先使用明确、可停止的 RunLoop observation / watchdog 机制，并严格控制自身开销。

### Runtime

- [x] Network。
- [x] UIViewController Lifecycle。
- [x] Logs。
- [x] Leak。
- [x] Crash markers（仅能记录可安全捕获的信息）。
- [x] App lifecycle / Scene lifecycle。

## 26.4 Timeline

统一时间轴示意：

```text
Time      0s        1s        2s        3s
          │---------│---------│---------│
CPU       ────╮──────╯───────────────
Memory    ────────╮───────────────╮──
FPS       ███████░░███░████████████
Hitch                █
Network        ├──────────┤
Lifecycle   ├──────────────────────
Logs          •   •      •  •
```

支持：

```text
horizontal scroll
zoom / range selection
track show / hide
category filter
event selection
cross-track timestamp correlation
```

点击某个 Hitch 时，应该能关联同一时间附近的：

```text
Main Thread Stall
Network event
Lifecycle event
Log
Memory change
Current Scene / VC
```

## 26.5 Network Track

优先复用 `URLSessionTaskMetrics` / 现有 Network Collector 可获得的信息，支持：

```text
request start / end
method / URL（按隐私策略脱敏）
status code
request / response bytes
duration
DNS / connect / TLS / TTFB（可获得时）
retry / cache / cancellation markers
```

Network Instruments 不应迫使 Network Core 依赖 Debug。

## 26.6 Lifecycle / Leak Track

利用 5.10.x Collector：

```text
viewDidLoad
viewWillAppear
viewDidAppear
viewWillDisappear
viewDidDisappear
expected deinit
actual deinit
possible leak
```

Timeline 可以显示对象生命周期区间；Leak 只提供“潜在泄漏”诊断，不把弱引用延迟检查包装成绝对结论。

## 26.7 Logs Track

Core 日志通过 Logging Contract 进入 Debug Sink，再写入 Session：

```text
Core Logger
   ↓
Log Contract
   ↓
Debug Log Sink
   ├─ LocalConsole
   └─ PTInstrumentSession
```

支持 level / category / text filter。

## 26.8 Custom Trace

提供业务侧自定义 trace，但保持 API 小而稳定。

建议：

```swift
PTTrace.measure("Image Decode") {
    decodeImage()
}

try await PTTrace.measure("Load User") {
    try await loadUser()
}
```

也可提供显式 token：

```swift
let trace = PTTrace.begin("Checkout")
// ...
trace.end()
```

必须处理：

```text
nested trace
async cancellation
重复 end
跨线程 timestamp
metadata Sendable boundary
```

## 26.9 Session / Export / Import

第一阶段建议自定义：

```text
.pttrace
```

逻辑结构可包含：

```text
session.json
summary.json
events.*
samples.*
network.*
logs.*
```

具体二进制 / JSON 格式在实现阶段根据性能决定，不在路线图中提前锁死。

要求：

- [x] Session 可 start / stop。
- [x] 可保存历史记录。
- [x] 可导出。
- [x] 可重新导入查看。
- [x] 大 Session 有容量 / 时间 / sample rate 限制。
- [x] Export 默认执行敏感信息脱敏策略。

## 26.10 Debug Dashboard

Instruments 之前或同时建立统一入口：

```text
PTools Debug

Overview
FPS / Memory / CPU / Network / Leaks / Errors

Tools
Console
Network
Inspector
Lifecycle
Leaks
Crash
Performance
Instruments
```

Dashboard 只消费 Debug Foundation，不成为新的数据源。

## 26.11 性能开销与采样策略

PTInstruments 本身不能成为明显性能问题。

必须建立：

```text
Disabled baseline
Debug enabled baseline
Recording baseline
Timeline UI open baseline
```

采样策略必须可配置：

```text
CPU / memory interval
FPS display link lifecycle
max event count
max session duration
max trace size
network body capture policy
log retention
```

不提前硬编码一个缺乏实测依据的 CPU 百分比目标；以 5.10.x baseline 和真实设备回归确定预算，并在 CI / release report 中固定。

## 26.12 隐私与发布边界

- [x] Network body / header 默认不完整持久化敏感字段。
- [x] token / cookie / authorization 支持统一 redaction。
- [x] Export 前再次执行脱敏。
- [x] Debug / Diagnostics target 默认不污染 Production Core。
- [x] 宿主明确启用时才能记录高成本 / 高敏感 Instrument。
- [x] Session metadata 不收集与诊断无关的用户数据。

## 26.13 5.11.x 暂不实现

第一版不以“完整复制 Xcode Instruments”为目标，以下能力延后评估：

```text
完整 Time Profiler call tree
Allocations object graph
System Trace
Metal System Trace
Mach thread sampling + stack unwinding + symbolication
dSYM profiler pipeline
```

原因：这些能力会显著提高实现复杂度、运行时风险和平台审核边界，不应阻塞 5.x Debug 诊断体系落地。

## 26.14 推荐版本切片

```text
5.11.0 Instruments Core / Session / Recorder
5.11.1 FPS / Frame Time / Hitch
5.11.2 CPU / Memory / Main Thread Stall
5.11.3 Network / Lifecycle / Logs / Leak Tracks
5.11.4 Timeline Model / Storage
5.11.5 Timeline UI
5.11.6 Event Inspector / Filter / Correlation
5.11.7 Custom Trace / Export / Import
5.11.8 Overhead / Privacy / Real-App Regression
5.11.9 Final 5.x Baseline + 6.0 Rehearsal
```

## 26.15 5.11.x 验收

- [x] Instruments 不重复安装已有 Collector / swizzle。
- [x] FPS / Memory / CPU / Stall 能形成同一 Session 时间基线。
- [x] Network / Lifecycle / Log / Leak 可以跨 Track 关联。
- [x] Timeline 支持长 Session 的增量加载或等价性能策略。
- [x] Session start/stop 不泄漏 Timer / DisplayLink / Observer。
- [x] `.pttrace` 可导出并重新打开。
- [x] Debug disabled 时 Instruments 不产生后台采样。
- [ ] Recording overhead 有真实设备 baseline。
- [ ] PTools Example / CrazyDashboard / 至少一个真实业务 App 完成回归。
- [ ] iOS 17 / iOS 26、Light / Dark、横竖屏、多 Scene 回归。
- [ ] 经典 Console / Inspector / Network Debug 入口保持兼容。

## 26.16 5.11.9：最终 5.x 基线与 6.0 Rehearsal

5.11.9 才执行原计划中“最终 5.x”应承担的工作：

```text
Feature Freeze
release/6.0-rehearsal
冻结 module graph
冻结 public API
冻结 deprecated deletion list
冻结 migration guide
完整 build matrix
真机 / 多 Scene / Instruments 回归
真实宿主迁移演练
```

在 `release/6.0-rehearsal` 上才真正删除已登记 deprecated API，并验证 PTools Example、CrazyDashboard 和其他真实宿主的迁移成本。

---

# 27. 6.0 准入条件

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
- [ ] Core 不存在 `LocalConsole` / Inspector / DebugWindow / Debug Configuration 等 Debug 类型反向引用。
- [ ] `PTDebugManager` / Plugin / Event / Collector 边界稳定。
- [ ] `LocalConsole` 已回归 Console 职责，并通过兼容层保留经典入口。
- [ ] PTInstruments 复用 Debug Collectors，不维护重复 swizzle / monitor。

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

- [ ] deprecated API 至少经过一个已发布的 5.x 兼容周期，并在 5.11.9 rehearsal 验证删除。
- [ ] 每个删除项有 replacement。
- [ ] `MIGRATION_6.md` 有示例。
- [ ] 5.11.9 Example 不再调用待删除 API。
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
- [ ] Debug Window 多 Scene / Sheet / Present / Keyboard / Rotation 回归。
- [ ] PTInstruments Recording overhead baseline。
- [ ] `.pttrace` 导出 / 导入与敏感信息脱敏回归。
- [ ] VoiceOver。
- [ ] Reduce Motion。
- [ ] Reduce Transparency。
- [ ] Portrait。
- [ ] Landscape。
- [ ] Split View。
- [ ] Multi Scene。

---

# 28. 6.0 建议删除内容

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

# 29. 6.0 不建议为了“干净”而删除的东西

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

# 30. 建议新增的质量脚本

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
validate_debug_dependency_direction.sh
validate_debug_swizzle_registry.sh
validate_trace_redaction.sh

report_dependency_graph.sh
report_large_swift_files.sh
report_singletons.sh
report_concurrency_exceptions.sh
report_public_api.sh
report_deprecated_api.sh
report_debug_reverse_refs.sh
report_debug_overhead.sh
report_instruments_session_size.sh
```

---

# 31. 推荐 Issue / Task ID 规范

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

DEBUG-5100-xx ... DEBUG-5109-xx
INST-5110-xx ... INST-5119-xx
```

这样不会再全部塞进 `CORE-xxx`。

---

# 32. 推荐每个版本的 Commit 顺序

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

# 33. 每个版本统一 Definition of Done

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
- [ ] 涉及 Debug 时：Debug disabled / enabled 双路径回归。
- [ ] 涉及 Debug Window 时：多 Scene / present / sheet / keyboard 回归。
- [ ] 涉及 Instruments 时：Recording start/stop、Session 释放和 overhead baseline。

## Docs

- [ ] CHANGELOG。
- [ ] ROADMAP。
- [ ] RELEASE。
- [ ] MIGRATION。
- [ ] README（如果 API 有变化）。

---

# 34. 最推荐的实际执行顺序

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
└─ Pre-Debug architecture validation

5.9.9
│
└─ Pre-Debug stable baseline

5.10.x
│
├─ Core / Debug 单向依赖
├─ Debug Configuration / Logging 解耦
├─ PTDebugManager / Plugin / Event Foundation
├─ LocalConsole 拆责
├─ Window / Scene 稳定化
└─ Collectors 统一迁移

5.11.x
│
├─ PTInstruments Core / Session
├─ FPS / CPU / Memory / Hitch / Stall
├─ Network / Lifecycle / Logs / Leak Tracks
├─ Timeline / Event Inspector
├─ Custom Trace / Export / Import
└─ 5.11.9 Final 5.x + 6.0 rehearsal

6.0
│
└─ 删除已经完整迁移并在 5.11.9 rehearsal 验证的 legacy API
```

---

# 35. 优先级

## P0：必须在 6.0 前完成

1. Core Dependency Diet。
2. SPM / CocoaPods parity。
3. PermissionCore 去 UI。
4. Network mutable/shared concurrency。
5. Navigation delegate ownership。
6. PTCollectionView internal split。
7. API migration inventory。
8. Third-party build blockers。
9. Debug Foundation 解耦与稳定化。
10. PTInstruments 核心诊断链路与 5.11.9 6.0 rehearsal。

---

## P1：强烈建议

1. Theme / Appearance。
2. Media Network decoupling。
3. Debug Dashboard / Timeline 体验完善。
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

# 36. 最终判断

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

如果严格按照这份路线执行，5.11.9 应该成为一个：

> **公开 API 仍兼容 5.x，Debug Foundation 与 PTInstruments 已稳定，同时内部结构已经基本达到 6.0 形态的版本。**

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

# 37. 仓库审查参考点

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

# 38. 可直接复制到 GitHub Project 的 Milestone

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

- [x] CORE-581-01 PToolsCore
- [x] CORE-581-02 UIFoundation
- [x] CORE-581-03 Core file classification
- [x] CORE-581-04 Legacy forwarding
- [x] CORE-581-05 Umbrella compatibility（SwiftPM；CocoaPods/Xcode framework membership 延后）

## Milestone: 5.8.2 Permission

- [x] PERM-582-01 PermissionCore
- [ ] PERM-582-02 PermissionUI（状态模型/设置桥接已落地，legacy UIKit 类型完整迁移待后续）
- [x] PERM-582-03 Minimal targets
- [x] PERM-582-04 Async API
- [ ] PERM-582-05 System service separation（Location/Bluetooth 生命周期切片已落地，完整服务协议待后续）

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

## Milestone: 5.9.8 Pre-Debug Validation

- [ ] 5.9.x architecture validation
- [ ] Debug dependency audit baseline
- [ ] Core -> Debug reverse reference scan
- [ ] LocalConsole responsibility inventory
- [ ] Real host risk inventory

## Milestone: 5.9.9 Pre-Debug Stable Baseline

- [ ] Full regression for 5.9.x
- [ ] Full build matrix
- [ ] Freeze pre-5.10 public API baseline
- [ ] Freeze performance baseline
- [ ] Freeze Debug dependency baseline
- [ ] Tag 5.9.9

## Milestone: 5.10.x Debug Foundation

- [x] DEBUG-5100-01 Core / Debug dependency contract
- [x] DEBUG-5100-02 Debug preferences migration
- [x] DEBUG-5100-03 Core runtime Debug special-case removal
- [x] DEBUG-5102 Logging / Debug Log Sink
- [x] DEBUG-5103 PTDebugManager / Plugin / Event Foundation
- [x] DEBUG-5104 LocalConsole responsibility split
- [x] DEBUG-5105 Debug Window / Scene stabilization
- [x] DEBUG-5106 Network / Lifecycle / Console collectors
- [x] DEBUG-5107 Crash / Leak / Inspector / MockLocation collectors
- [ ] DEBUG-5108 Compatibility / overhead / regression

## Milestone: 5.11.x PTInstruments

- [x] INST-5110 Session / Recorder / Track contracts
- [x] INST-5111 FPS / Frame Time / Hitch
- [x] INST-5112 CPU / Memory / Main Thread Stall
- [x] INST-5113 Network / Lifecycle / Logs / Leak tracks
- [x] INST-5114 Timeline model / storage / sampling
- [x] INST-5115 Timeline UI
- [x] INST-5116 Event Inspector / filter / correlation
- [x] INST-5117 Custom Trace / .pttrace export / import
- [ ] INST-5118 Overhead / privacy / real-app regression
- [ ] Deprecated deletion rehearsal
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
- [x] DOC-597-03：新增 `EXAMPLE_MODULES_5_9.md`，登记 `PooTools-Example` 的真实页面入口、模块覆盖和回归清单；5.9.8 只做真实宿主迁移风险盘点，最终删除与迁移 rehearsal 后移到 5.11.9。
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
- [ ] 真实宿主项目迁移：5.9.8 先完成风险盘点；最终删除与迁移演练放到 5.11.9 rehearsal。
- [ ] 5.9.8 / 5.9.9：完成 Pre-Debug 验证与稳定基线；5.10.x 完成 Debug Foundation；5.11.9 再执行 6.0 rehearsal、完整 Xcode 矩阵和最终 5.x 基线。

已知外部阻断：Metal 工具链和部分 Kitura/Pods Swift 6 诊断。宿主重新接入旧版
Bugly 时还会重新引入二进制架构阻断。阻断解除前不得宣称 5.9.x 完整验收通过或创建发布标签。

## 5.10.x 当前实施记录（2026-09-12）

以下记录对应当前工作树的 5.10.x Debug Foundation 实施；代码落地和编译通过不等于真机、真实宿主或多 Scene 视觉回归已经完成。

### 已实施

- [x] DEBUG-5100-01：Core 增加通用 `PTUIKitRuntimeHooks`、Core 日志 sink 契约；Core 源码不再直接引用 LocalConsole、Inspector、Debug Window 或 Debug 偏好类型。新增 `Scripts/validate_debug_foundation_5_10.sh` 并接入质量门禁。
- [x] DEBUG-5100-02：新增 `PTDebugConfiguration` 与 `@MainActor PTDebugPreferences`，旧 UserDefaults key 可读取、写入并迁移，`PTCoreUserDefultsWrapper` 旧 Debug 属性改为 deprecated 兼容扩展。
- [x] DEBUG-5100-03：启动广告、导航、窗口、Context Menu、边框和展示回调改用 Core 通用 hook；Debug 语义集中在 `PTDebugRuntimeAdapter`。
- [x] DEBUG-5102：新增 `PTLogSink` / `PTLogSinkCenter`，`PTNSLog` 发布不可变 `PTLogEvent`，LocalConsole 只作为可选 sink 消费日志。
- [x] DEBUG-5103：新增 `PTDebugManager`、`PTDebugPlugin`、`PTDebugCollector`、`PTDebugEvent` 和 `PTDebugEventCenter`；事件只跨 actor 传递值类型快照。
- [x] DEBUG-5104：LocalConsole 回归显示、缓冲、菜单和经典兼容入口；Network、Lifecycle、Console、Crash、Leak、Inspector、MockLocation 启动职责迁入 Collector。多 Scene Debug session 使用 owner 引用计数。
- [x] DEBUG-5105：Debug window 按 `UIWindowScene` 管理，Scene disconnect 清理窗口、控制台 sink、事件 observer 和 root controller；窗口层级恢复集中到 `PTDebugWindowCoordinator`。
- [x] DEBUG-5106 / DEBUG-5107：Network、Lifecycle、Console、Crash、Leak、Inspector、MockLocation Collector 已建立并接入 `PTSwizzleRegistry` owner 记录，重复启动保持幂等。
- [x] 新增文档：`DEBUG_ARCHITECTURE_5_10.md`、`DEBUG_DEPENDENCY_GRAPH_5_10.md`、`DEBUG_PUBLIC_API_5_10.json`、`DEBUG_SWIZZLE_REGISTRY_5_10.md`、`DEBUG_SCENE_REGRESSION_5_10.md`、`DEBUG_OVERHEAD_BASELINE_5_10.md`。

### 已验证

- [x] `PToolsCore` 独立 SwiftPM 构建通过。
- [x] `swift package dump-package`、Core source contract、依赖方向和 Debug Foundation 静态门禁通过。
- [x] `PooTools-Example` iOS Simulator Debug / Release 完整 Xcode 构建通过；最后一次 Debug 日志位于 `/tmp/ptools-510-debug.G6wiU8/xcodebuild-final-debug-warning-fix-6.log`，Release 日志位于 `/tmp/ptools-510-release.qYNzP1/xcodebuild-final-release-warning-fix-2.log`。

### 待验证或阻断

- [ ] DEBUG-5108：CocoaPods lint、SPM/CocoaPods/Example 三入口最终矩阵、真实多 Scene/Scene disconnect/键盘/分屏/横竖屏回归、Debug enabled/disabled 真机性能基线尚未完成；Release 完整 Xcode 构建已通过。
- [ ] 5.10.9 Stable Baseline：需在上述运行时验证和外部 Pods 阻断分类完成后再标记，不创建 5.10.x 版本 tag。

当前代码未修改第三方依赖、Pods 源码、产品版本号或 tag；外部 KituraContracts、Metal 工具链和其他 Pods 的既有诊断仍需单独归类，不能计入 PooTools 源码通过。

## 5.11.x 当前实施记录（2026-09-13）

以下记录只反映当前工作树已经实现的 PTInstruments 代码、门禁和文档；完整 Xcode 构建通过
不等于真实设备开销、真实宿主或多 Scene 运行时回归已经完成。

### 已实施

- [x] INST-5110：新增 `PTInstrument`、`PTInstrumentSession`、`PTInstrumentRecorder`、Track、Sample、Event、Timeline 和 Sampling Policy；Session actor 独占可变录制状态。
- [x] INST-5111：使用活动屏幕真实刷新率采集 FPS / Frame Time，并按实际 frame budget 记录 Hitch / Severe Hitch。
- [x] INST-5112：新增 CPU、Memory 和可取消 MainActor Stall 采样；采样 Task、DisplayLink 和停止路径均可回收。
- [x] INST-5113：消费既有 Debug Event / Log Sink；Network、Lifecycle、Leak、App/Scene Lifecycle 形成统一事件轨道，不重复安装 Collector 或 swizzle。
- [x] INST-5114：新增有限容量 Session、时间查询、跨轨道 correlation、历史记录、`.pttrace` 存储和策略上限。
- [x] INST-5115 / INST-5116：新增时间线横向滚动、缩放、轨道显示、文本过滤、时间范围和事件检查器。
- [x] INST-5117：新增 `PTTrace` 同步/异步测量、显式 token、嵌套 parent ID、重复结束保护及导入导出脱敏。
- [x] INST-5118-代码部分：新增隐私 Redactor、显式 crash marker、开关和采样上限；Debug Network 使用已有协议拦截器发布不可变请求摘要。
- [x] 质量门禁：新增 `Scripts/validate_instruments_5_11.sh` 并接入 `Scripts/validate_quality_scans.sh`，检查数据链路、重复 Collector / swizzle、隐式启动和不安全声明。
- [x] 文档：新增 `INSTRUMENTS_5_11.md`、`INSTRUMENTS_OVERHEAD_BASELINE_5_11.md` 和 `INSTRUMENTS_PRIVACY_5_11.md`。

### 已验证

- [x] `PooTools-Example` iOS Simulator Debug 完整 Xcode 构建通过；日志为
  `/tmp/ptools-511-debug-membership-fixed-4.log`，且新 PTInstruments 文件已加入 PooTools target。
- [x] `PooTools-Example` iOS Simulator Release 完整 Xcode 构建通过；日志为
  `/tmp/ptools-511-release-membership-final.log`，且新 PTInstruments 文件已加入 PooTools target。
- [x] `pod install --no-repo-update` 已重新生成被忽略的 Pods 工程，使新 Debug 源文件进入实际编译；
  `Podfile.lock`、第三方依赖版本和 Pods 源码未修改。
- [x] 质量扫描、构建入口检查、SwiftPM manifest 检查和 `git diff --check` 均通过；最终构建日志中
  未匹配到 `PooToolsSource` 路径下的 `warning:` 或 `error:`。

### 待验证或阻断

- [ ] INST-5118：真实设备 Disabled / Debug enabled / Recording / Timeline UI 四态开销基线尚未采集；CPU、内存、FPS、主线程卡顿和长会话数值不能由 Simulator 构建推断。
- [ ] PTools-Example、CrazyDashboard 和至少一个真实业务宿主的导出、导入、多 Scene、横竖屏、Light/Dark、iOS 17/iOS 26、VoiceOver、Reduce Motion/Transparency 回归尚未完成。
- [ ] `PooTools-Example` 当前 Xcode 依赖环境仍有外部 Pods / Metal toolchain 诊断；这些提示已与
  PooTools 源码结果分开，不能由源码构建替代运行时验收。
- [ ] INST-5119 / 5.11.9：deprecated 删除演练、Feature Freeze、完整构建矩阵和 6.0 rehearsal 不在本次实现中提前标记完成。

实施细节和使用示例见 `INSTRUMENTS_5_11.md`；开销数据填写规则见
`INSTRUMENTS_OVERHEAD_BASELINE_5_11.md`，隐私检查见 `INSTRUMENTS_PRIVACY_5_11.md`。
