# PTools 5.17.x UI Components / Utility 结账清单

本清单对应 `PTools_Pre_6.0_Full_Module_Optimization_Plan.md` 的 5.17.x 范围。
当前代码目标为 iOS 17+ / Swift 6+，不删除 5.x 公开入口，也不修改第三方 Pods 源码。

## 结账口径

- `✅ 源码契约`：已确认源码归属、依赖边界、生命周期和静态门禁入口。
- `⚠️ 宿主回归`：真实宿主、真机、Stage Manager、VoiceOver 和视觉结果仍需在发布前执行。
- UI 组件默认由 UIKit 的 MainActor 隔离承载；跨模块数据使用值类型或显式快照。
- Timer、DisplayLink、Task、动画和 observer 必须在隐藏、复用、离屏和释放时停止。
- 外部依赖只做接入边界检查，不在本仓库复制或修改其实现。

## 模块逐项清单

| Module | Owner | Dependency | Lifecycle | Test | Example | Doc | 6.0 decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CustomerLabel | PTools UI | Core / QuartzCore | reuse / deinit | static + visual | PooTools Example | podspec | 保留兼容入口 |
| ProgressBar | PTools UI | Core | value update / reuse | static + visual | PooTools Example | podspec | 保留兼容入口 |
| PageControl | PTools UI | Core | DisplayLink start/stop | static + visual | PooTools Example | podspec | 保留 typed API |
| Loading | PTools UI | Core | show / hide / deinit | static + scene | PooTools Example | podspec | 收口到 overlay contract |
| HUD | PTools UI | Core / ProgressBar | show / hide / timer | static + scene | PooTools Example | podspec | 收口到 overlay contract |
| Share | PTools UI | CustomerLabel | present / dismiss | static + iPad | PooTools Example | podspec | 保留兼容入口 |
| SearchBar | PTools UI | Core / PTLoadImageFunction | debounce / cancel / reuse | `validate_517_ui.sh` + visual | DebugNetwork | this file | 保留 typed handler，兼容 delegate |
| Stepper | PTools UI | Core | value / accessibility | static + visual | PooTools Example | podspec | 保留兼容入口 |
| BankCard | PTools UI | Core | input / validation | static + keyboard | PooTools Example | podspec | 保留兼容入口 |
| CheckBox | PTools UI | Core | control state / reuse | static + VoiceOver | PooTools Example | podspec | 保留兼容入口 |
| CodeView | PTools UI | Core | input / focus | static + keyboard | PooTools Example | podspec | 保留兼容入口 |
| Country | PTools UI | Core | list / selection | static + localization | PooTools Example | podspec | 保留兼容入口 |
| Guide | PTools UI | Core / PageControl / Instructions | show / dismiss | static + rotation | PooTools Example | podspec | 外部引导适配器保留 |
| Input | PTools UI | Core / PhoneNumberKit | focus / keyboard / deinit | static + keyboard | PooTools Example | podspec | 逐步减少 IQKeyboard 依赖 |
| Keyboard | PTools UI | Core | input accessory / dismiss | static + hardware keyboard | PooTools Example | podspec | 保留兼容入口 |
| RateView | PTools UI | Core | value / reuse | static + Dynamic Type | PooTools Example | podspec | 保留兼容入口 |
| ScrollBanner | PTools UI | Core | timer / page reuse | static + rotation | PooTools Example | podspec | 保留 canonical Banner |
| Segmented | PTools UI | Core | selection / layout | static + RTL | PooTools Example | podspec | 保留兼容入口 |
| HandSign | PTools UI | Core | touch / reset | static + rotation | PooTools Example | podspec | 保留兼容入口 |
| Slider | PTools UI | UIFoundation / SnapKit | value / layout | static + size class | PooTools Example | podspec | 保留兼容入口 |
| Layout | PTools UI | Core | constraint / safeArea | static + rotation | PooTools Example | podspec | 保留兼容入口 |
| PagingControl | PTools UI | Core / JXPagingView / JXSegmentedView | page / reuse | static + scroll | PooTools Example | podspec | 外部分页适配器保留 |
| Picker | PTools UI | Core | show / embed / dismiss | static + scene | PooTools Example | `PTBasePickerView` | 保留 typed picker API |
| TipsView | PTools UI | Core | timer / animation / window | static + visual | PooTools Example | podspec | 收口到 overlay contract |
| Circle | PTools UI | Core | draw / bounds | static + rotation | PooTools Example | podspec | 保留兼容入口 |
| MessageKit | PTools UI | Core | message reuse | static + keyboard | PooTools Example | podspec | 保留兼容入口 |
| NotificationBanner | PTools UI | Core / NotificationBannerSwift | present / dismiss | dependency + scene | PooTools Example | podspec | 外部适配器保留 |
| PopoverKit | PTools UI | Core / Popovers | present / dismiss | dependency + iPad | PooTools Example | podspec | 外部适配器保留 |
| Tabbar | PTools UI | Core / Base | selection / rotation | static + multi-scene | PooTools Example | architecture docs | 保留 Base 兼容入口 |
| Instructions | PTools UI | Core / Instructions | coachmark / dismiss | dependency + rotation | PooTools Example | podspec | 外部适配器保留 |
| Appz | PTools UI | Core / Appz | per-call | dependency + URL scheme | PooTools Example | podspec | Swift 5 外部适配器保留 |
| Flag | PTools UI | Core / FlagKit | image / reuse | dependency + RTL | PooTools Example | podspec | 外部适配器保留 |
| WhatsNewsKit | PTools UI | Core | feed / reuse | static + Dynamic Type | PooTools Example | podspec | 保留兼容入口 |
| iOS17Tips | PTools UI | Core | present / dismiss | static + scene | PooTools Example | podspec | 保留兼容入口 |
| ChinesePinyin | PTools Utility | Core | per-call | static | PooTools Example | podspec | 保留兼容入口 |
| DirtyWord | PTools Utility | Core / resources | per-call / cache | static + resource | PooTools Example | podspec | 保留 typed result |
| Speech | PTools System | PermissionCore | start / stop / invalidate | static + permission | PooTools Example | podspec | 保留兼容入口 |
| Router | PTools Core/UI | Core | resolve / jump / cancel | static + scene | PooTools Example | architecture docs | 保留安全 typed API |
| SpeedPanel | PTools UI | Core | show / hide / timer | static + scene | PooTools Example | podspec | 保留兼容入口 |
| ZipArchive | PTools Utility | Core / SSZipArchive | archive / cancel | dependency + path | PooTools Example | podspec | 外部安全适配器保留 |
| GCDWebServer | PTools Utility | Core / GCDWebServer | start / stop / background | dependency + port | PooTools Example | podspec | 外部服务适配器保留 |
| WebKit | PTools UI | Core / WebKit | navigation / process / deinit | static + host | PooTools Example | podspec | 收口 typed WebKit adapter |

## 通用验收矩阵

每个 UI 模块都按以下顺序检查：

1. MainActor 隔离、Auto Layout、safe area、Dynamic Type、RTL、VoiceOver、Dark Mode、旋转和 size class。
2. 可复用视图的异步任务、Timer、DisplayLink、observer 和动画在 `prepareForReuse`、隐藏、离屏和释放时结束。
3. 多 Scene 入口使用 `PTSceneContext`；展示型 UI 不再直接读取全局 `keyWindow` 或 `AppWindows`。
4. 运行 `bash Scripts/validate_517_ui.sh`，再执行 Xcode Simulator Debug / Release；静态通过不替代真实宿主视觉和交互回归。

## 已收口的 canonical 入口

- 图片：`PTLoadImageFunction.loadImage(source:)`。
- 视频缩略图：`PTVideoThumbnailService`。
- 媒体保存：`PTMediaSaveService`。
- Picker 嵌入：`PTBasePickerView.show(in:animated:)` 与 `dismiss(animated:)`。
- Alert 生命周期：`PTAlertManager.dismissAll(completion:)`。
- 场景：`PTSceneContext`；MainActor 调度：`PTMainActorBridge`。
- SearchBar：`searchHandler`、`cancelSearch()`、`clearSearch()`、`refreshLocalizedText()`。

## 5.17 发布边界

源码契约和静态门禁完成不代表真实设备上的视觉、键盘、VoiceOver、Stage Manager、WebKit 进程恢复或外部服务行为已经证明。未完成的宿主回归必须保留在发布报告中，不能通过修改第三方 Pods 或伪造测试结果消除。
