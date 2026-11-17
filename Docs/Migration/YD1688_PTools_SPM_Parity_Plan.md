# PTools Swift Package Manager 兼容与 YD1688 迁移修复方案

> 状态：**PTools SPM 兼容 Product 已开始落地，42/42 静态映射通过；PTools 全量 iOS 编译 / 真机验收未开始**。方案落点：`crazypoo/PTools@master`；参考使用方：`crazypoo/YD1688@main`。本文件是当前有效的待办与验收清单，不是迁移完成证明。

## 目标与边界

- **目标**：让 YD1688 `Podfile` 中全部 **42 个 `PooTools/...` subspec** 在 PTools 的 **Swift Package Manager（SPM / SwiftPM）** 分发中有功能等价、可链接、可编译、可集成的对应入口。
- **先完善 PTools**，再在 YD1688 独立迁移、验证；本计划不直接改 YD1688，不删除当前 Podfile、podspec，也不改变 App 业务 API 或交互。
- 维持 CocoaPods 旧版兼容期。CocoaPods Trunk **计划于 2026-12-02 转为只读**，是中央仓库不再收新版本，**不等于现有 `pod install` 当天失效**；PTools 已经采用 `:git` 源，仍需迁移以获得长期、可靠的 SwiftPM 分发。[官方说明](https://blog.cocoapods.org/CocoaPods-Specs-Repo/)
- 当前 `Package.swift` 为 `swift-tools-version: 6.0`、iOS 17+；YD1688 Podfile 也是 iOS 17。勿降低 deployment target；Swift 6 严格并发与真机行为分别验证。
- 优先保持旧 `import PooTools` API 可达性：SPM `product` 名称、Swift `module` 名称、CocoaPods `subspec` 名称不能混为一谈，必要时用明确的兼容层，不应把单一 Core 拆分造成大面积调用点变化。

## 盘点基线与关键发现

| 项目 | 静态盘点 |
|---|---|
| `YD1688/Podfile` | 42 个不同的 `PooTools/...` 引用 |
| `PTools/PooTools.podspec` | 168 个 subspec 声明（包含部分兼容 alias） |
| `PTools/Package.swift` | 173 个 `.library` 声明（可能含同一 target 的多个 product alias）；**声明不等于实际编译可用** |
| 直接或已明确重命名的候选 SPM 产品 | 42 / 42（含 3 个新增兼容 Product） |
| 兼容别名 Product 已补齐 | 3 / 42：`Tabbar`、`NotificationBanner`、`Flag`（编译/业务等价性待验收） |
| YD1688 当前锁定 PTools Git commit | `3f9f7d5b604877bdb4a48d32a53944734c9c5072`（Podfile.lock）；它与 PTools master 的当前源码版本未必一致，须比较 API/行为 |
| 验收现状 | 已完成远端静态声明校验与独立 SwiftPM alias 示例构建；尚未运行真实 PTools `swift package resolve` / 42 项 iOS 构建 / 真机或 App Archive |

### 三个缺少同名 product 的特殊项（P0）

1. **`PooTools/Tabbar`**：podspec 仅依赖 `PooTools/Core`，额外设置 `POOTOOLS_TABBAR`；未声明独立 `source_files`。现已添加 `PooToolsTabbar` product，复用 `ptools` target。先搜索 Tabbar 公开 API / 条件编译是否已包含在 `ptools` target；若已包含，应建立并验证 `PooTools/Tabbar` → `ptools` 的映射，必要时添加轻量兼容 product，而不是复制源码。若遗漏条件编译，补等价 `swiftSettings` 并测试。
2. **`PooTools/NotificationBanner`**：podspec 本身是指向 `PooTools/Banner` 的**兼容别名**，没有独立源码；SPM 已声明 `PooToolsBanner`，现追加 `PooToolsNotificationBanner` product alias。优先映射到 `PooToolsBanner`，核对旧接口和 UI 行为。仅在确有旧入口需要维持时追加兼容 product/adapter。
3. **`PooTools/Flag`**：podspec 仅依赖 `PooTools/Core`，不含独立源码；现已添加 `PooToolsFlag` product，复用 `ptools` target；不将 `FlagKit` 偷偷并入。先扫描 YD1688 是否实际使用 PTools Flag API、是否来自独立 `FlagKit`，防止重复引入或错误归属；若只是 Core 兼容占位则映射 `ptools`，否则补明确的可用 product 和实现/依赖。

> **特别注意**：`PooTools/Core` 对应综合 `ptools`（不是只有 Foundation 功能的 `PToolsCore`）。`PooTools/VideoCache` 的 SPM 产品已作为 `ptools` target alias；`BilogyID` 对应 `PooToolsBioID`，`NetWork` 对应 `PooToolsNetWork`。这些要验证旧公开 API，不能只比较字符串名称。

## 42 个使用方 Pod → SPM 候选对应表

标记：**候选** = manifest 静态声明存在，*未通过独立构建/链接/功能验收*；**需核验** = 兼容 alias 或功能归属未确认。

| YD1688 Pod subspec | PTools SPM Library Product（候选） | 状态 / 注释 |
|---|---|---|
| Core | `ptools` | 候选；非 `PToolsCore` |
| ScanQRCode | `PooToolsScanQRCode` | 候选 |
| NetWork | `PooToolsNetWork` | 候选；旧拼写 |
| Acknowledgements | `PToolsAcknowledgements` | 候选；资源/生成器需验收 |
| Date | `PToolsDate` | 候选 |
| WebBridge | `PToolsWebBridge` | 候选 |
| PagingControl | `PooToolsPagingControl` | 候选 |
| ScrollBanner | `PooToolsScrollBanner` | 候选 |
| RateView | `PooToolsRateView` | 候选 |
| Stepper | `PooToolsStepper` | 候选 |
| Input | `PooToolsInput` | 候选 |
| Picker | `PooToolsPicker` | 候选 |
| PhotoPicker | `PooToolsPhotoPicker` | 候选 |
| CustomerLabel | `PooToolsCustomerLabel` | 候选 |
| Tabbar | `PooToolsTabbar`（module: `ptools`） | 已声明兼容 Product；真实构建待验收 |
| Loading | `PooToolsLoading` | 候选 |
| WhatsNewsKit | `PooToolsWhatsNewsKit` | 候选 |
| MediaViewer | `PooToolsMediaViewer` | 候选 |
| ProgressBar | `PooToolsProgressBar` | 候选 |
| MessageKit | `PooToolsMessageKit` | 候选 |
| SocketKit | `PooToolsSocketKit` | 候选 |
| NotificationPermission | `PTNotificationPermission` | 候选 |
| CameraPermission | `PTCameraPermission` | 候选 |
| LocationPermission | `PTLocationPermission` | 候选 |
| Circle | `PooToolsCircle` | 候选 |
| NotificationBanner | `PooToolsNotificationBanner`（module: `PooToolsBanner`） | 已声明兼容 Product；真实构建待验收 |
| CodeView | `PooToolsCodeView` | 候选 |
| BilogyID | `PooToolsBioID` | 候选；保留错拼兼容行为 |
| SmartScreenshot | `PooToolsSmartScreenshot` | 候选 |
| Flag | `PooToolsFlag`（module: `ptools`） | 已声明兼容 Product；`FlagKit` 仍宿主负责 |
| Router | `PooToolsRouter` | 候选 |
| Share | `PooToolsShare` | 候选 |
| DataEncrypt | `PooToolsDataEncrypt` | 候选 |
| WebKit | `PooToolsWebKit` | 候选 |
| OSSKitSpeech | `PooToolsOSSKitSpeech` | 候选 |
| ImageEditor | `PooToolsImageEditor` | 候选 |
| VideoEditor | `PooToolsVideoEditor` | 候选；资源需核验 |
| VideoCache | `PooToolsVideoCache` | 候选；product alias → `ptools` |
| Hud | `PooToolsHud` | 候选 |
| FilterCamera | `PooToolsFilterCamera` | 候选；关联多模块的 target |
| Popover | `PooToolsPopover` | 候选 |
| AppIntents | `PToolsAppIntents` | 候选 |

## 闭环修复计划（每项实现与验收状态分离）

### P0 — Manifest / API 语义与 42/42 可解析

- [ ] **SPM-001**：增加可维护的 `Pod subspec → SPM product → target → module/import → source files` 映射真值表；扫描 YD1688 的 import/API 用量，细化三个 alias 的实际归属；确保 42/42 无缺项、不出现重复编译。
- [ ] **SPM-002**：修复 Tabbar、NotificationBanner、Flag 的**实际** SPM 覆盖差异。不得仅为凑齐数量创建空壳 target；别名应复用已有实现，并为旧 API 配独立编译验收。

#### 已落地的最小开发子闭环（Q 仍待真人）

- [x] **SPM-001/AU-a：** 以 `YD1688/main/Podfile` 作为快照建立 `Scripts/CI/yd1688_spm_products.json`，明确全部 42 个 subspec 的 SPM Product / Target / 实际 import module；静态对照 42/42，无缺失。
- [ ] **SPM-001/AU-b：** 真实 YD1688 调用点的旧 API 符号和完整源码归属仍需独立 iOS 编译核验；静态表不等于业务等价性。
- [x] **SPM-002/AU-a：** 在 `Package.swift` 增加 `PooToolsTabbar → ptools`、`PooToolsFlag → ptools`、`PooToolsNotificationBanner → PooToolsBanner` 三个兼容 Product，均复用旧 Target，无重复源码。
- [x] **SPM-002/AU-b：** 隔离 SwiftPM 示例验证三个 Product alias 使用相同 Target 的 manifest 解析与构建均通过（Linux Swift 工具链；不替代真实 PTools/iOS 编译）。
- [ ] **SPM-002/AU-c：** 在 macOS iOS SDK 下实际编译、链接和调用 Tabbar/Banner/Flag 公开 API；未执行。
- [x] **SPM-007/AU-a：** 已添加 `Scripts/CI/check_yd1688_spm_products.py` 静态校验器及 `Tests/Fixtures/YD1688SPMProbe` 42 Product / 39 Module 消费者夹具；远端独立静态交叉核对无缺项。
- [x] **SPM-DEBUG-001/AU-a：** 修复 `PooToolsSource/Debug/PTDebugFunction.swift` 跨 target 缺少 `import PToolsDebugConsoleUI` 引发的 `Cannot find type 'PTConsoleWindow' in scope`；`PTConsoleWindow.debugWindowLevel` 改为 `public` 以供 `PooToolsDEBUG` 使用，CocoaPods 源文件归属不变。通过 9 项静态引用/target/访问级别核对；`Scripts/validate_debug_instruments_5_18.sh` 已补回归断言。
- [ ] **SPM-DEBUG-001/AU-b：** 在 macOS Xcode iOS SDK 中独立编译 `PToolsDebugConsoleUI`、`PooToolsDEBUG` 并执行 Debug 测试；**本次未运行**。
- [ ] **SPM-DEBUG-001/Q：** 用户真人真机调试控制台展示、隐藏、Scene 切换验收，待复检。
- [ ] **SPM-007/AU-b：** 在 PTools macOS 克隆中执行校验脚本并编译整个消费端 fixture（Debug/Release）；未执行，保留待验。
- [ ] **Q：** 用户真人真机验证；未进行。

验证命令（在 PTools 仓库根目录执行）：

```bash
python3 Scripts/CI/check_yd1688_spm_products.py
# 可选：与本地只读 YD1688 Podfile 实时比对，不修改 YD1688。
python3 Scripts/CI/check_yd1688_spm_products.py --reference-podfile ../YD1688/Podfile
swift package dump-package >/dev/null
bash Scripts/validate_module_parity.sh --check
cd Tests/Fixtures/YD1688SPMProbe
swift package resolve
# 使用安装有 Xcode iOS SDK 的 macOS 对该 library target 执行 iOS Debug/Release 编译。
```

- [ ] **SPM-003**：逐 target 核对 CocoaPods `subspec.dependency` 与 SPM `dependencies`，审核网络、扫码、消息、相册、权限、媒体编辑、弹层等链条；禁止循环依赖、重复符号、隐式全家桶兜底。
- [ ] **SPM-004**：审核 `POOTOOLS_*` 条件编译宏在 Pod 与 SPM 之间是否等价，特别是 `POOTOOLS_TABBAR`、`POOTOOLS_COCOAPODS`（在 SPM target 中亦存在）、permission split/embed、FilterCamera、VideoCache；定义并测试仅 Pod/仅 SPM 分支。

### P1 — 资源、第三方与构建可复现

- [ ] **SPM-005**：核对 `Core` 的 `PooToolsResource`、多语言 `.lproj`、`PrivacyInfo.xcprivacy`、图片/颜色资源、`VideoEditor` bundle、`Symbols` 资源；SPM 使用 `resources` / `Bundle.module` 或兼容资源加载器，不允许运行时只找 `Pods` bundle。
- [ ] **SPM-006**：核对 SPM 第三方包及可用产品：SnapKit、IQKeyboardManager、Kingfisher、Lottie、PhoneNumberKit、Harbeth、CryptoSwift、Alamofire 等；包括平台支持、版本 pin、隐式 Pod 依赖、Privacy Manifest、license、重复静态链接。对 YD1688 `post_install` 的改写行为逐项寻找**PTools 源码级**解决方案：Network.swift 移除 `PTCustomHTTPProtocol` 注入、Harbeth 重复链接处理、Header symlink 脚本补丁；迁移后绝不能依赖修改 `Pods/` 文件或 xcconfig。
- [ ] **SPM-007**：在 PTools 增加静态一致性脚本 + 最小化 SPM consumer fixture，自动验证 42 个产品的解析、import、公开符号调用、资源定位；同时防止未来新增/重命名 Pod subspec 时漏补 SPM。对单个产品做可重现测试后再做组合链接测试。

### P2 — 使用方迁移与真实验收

- [ ] **SPM-008**：从干净克隆运行 `swift package dump-package`、`swift package resolve` 与可用平台下的 `xcodebuild`/fixture；逐个独立产品和 42 项组合测试 Debug / Release，Swift 6 严格并发，iOS Simulator + device archive，排除 duplicate symbols / missing module / bundle lookup。**本项尚无真实测试证据**。
- [ ] **SPM-009**：PTools 通过验证后，在 YD1688 独立 PR 按模块迁移为 SPM；先固定 PTools Git revision 以消除 master 漂移，再用明确的语义版本 tag；先保留其他独立 Pod，并检测 Pod + SPM 混用是否重复链接。最终去除不再需要的 `post_install` 补丁、PTools Pod 引用，重建 lock/resolved 与许可证清单。
- [ ] **SPM-010**：真人真机 Q 验收：扫码和权限、图片选择与编辑、视频编辑与缓存、网络/debug 协议隔离、登录/输入/键盘、消息/Socket、页面弹层/HUD/Tabbar、Banner、地区旗帜、路由/AppIntents、Acknowledgements。与 Pods 基准录屏/功能结果比较，失败回写待修清单，不能自动勾 Q。
- [ ] **SPM-011**：输出 PTools 安装文档（Xcode → Add Package Dependencies、URL、版本策略、应选择的 Products、各 product 的 `import`）及兼容性矩阵；不要在文档中声称 SPM 已支持而没有构建证据。

### 每个最小闭环的状态规则

- **开发/静态验证（AU）**与**真机验证（Q）**必须分开记录；每完成一个最小闭环立即更新对应勾选与统计，不允许攒多个后补。
- 完成条件：实际修复代码 + 有效脚本/编译证据 + 可复现的消费者验证；未跑测试只能写“未验证”，不能将 manifest 声明计作通过。
- Q 只由用户真人真机验证后勾选；失败恢复待修状态。**不写更新时间线、过程流水账或重复的历史记录**。

## 最低验收口径

| 指标 | 目标 | 当前 |
|---|---|---|
| 42 项 Pod 对应项的静态候选覆盖 | 42/42 | **42/42（静态对照通过）** |
| 有确定且功能等价的 SPM 映射 | 42/42 | **未验收** |
| 每个产品可独立解析、编译、import | 42/42 | **未执行** |
| 42 项组合集成 Debug / Release | 通过 | **未执行** |
| 无资源缺失、重复链接及 Pods 专有补丁 | 通过 | **未执行** |
| YD1688 主工程 SPM 编译 / Archive | 通过 | **未执行** |
| 真人 Q 全部功能验证 | 通过 | **未执行** |

## 建议执行顺序

**SPM-001 → SPM-002 → SPM-003/004 → SPM-005/006 → SPM-007/008 → SPM-009 → SPM-010/011**。

目前只在 PTools 上实施 SPM 产品别名、映射和消费端验证夹具；**YD1688 代码、Podfile、项目设置均未修改**。实际产品构建/真机验收通过前不得声称迁移已完成。
