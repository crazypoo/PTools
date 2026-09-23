# Changelog

## Unreleased — 5.23.x

当前开发基线为 `5.23.0`；版本唯一来源为根目录 `VERSION`，`5.22.2` 是最近的正式基线。

- 5.23.0 移除 SwifterSwift 的源码导入、SwiftPM/CocoaPods 直接依赖和锁文件记录；新增 PTools 自有的 Sequence、Array、Dictionary、Optional、URL、RangeReplaceableCollection 与 UIView 兼容入口。
- 5.23.0 统一安全下标、JSON 序列化、查询参数、视图层级和圆角辅助逻辑，避免强制解包、重复实现和不稳定的随机顺序；新增迁移指南、类别规范、依赖审计和持续门禁。

- 5.22.0 从 SwiftPM、CocoaPods、`Package.resolved` 和 `Podfile.lock` 移除旧日志第三方依赖，新增实现路径扫描，确保交付源码不再直接依赖旧后端。
- 5.22.1 删除旧文件日志管理器的独立实现和 UI sink 兼容实现；`PTLogFileManager` 历史符号保留为仅转发 `PTLogger` 的适配器，`PTNSLog`、`PTOSLogger` 入口和 Debug UI 共用统一日志管线。
- 5.22.2 增加依赖策略、迁移指南、5.22 日志门禁和依赖矩阵复核，完成 API、性能、Debug、Core 与 SwiftPM/CocoaPods parity 收口。

## 5.22.2 — 2026-09-22

- 完成日志依赖移除、兼容层收口、依赖策略、迁移文档和发布前质量复核；5.23.0 在此正式基线上继续进行 Category 依赖替换。

- 5.21.0 将 PTools 生产 Swift 内部的直接 `DDLog*` 实现迁移到 `PTLogger`；`PTNSLog`、`PTLogEvent` 和旧 sink 继续作为兼容包装器保留。
- 5.21.1 新增有界 `PTMemoryLogDestination`、actor 所有的 Ring Buffer 和多订阅流；LocalConsole 与 PTInstruments Logs 复用同一个内存数据源。
- LocalConsole 增加 category、level 和关键字筛选，UI 更新改为批量刷新，不改变旧调试入口。
- 5.21.2 增加日志隐私脱敏 API、Network 请求/响应头脱敏、背压计数、drop policy、后台 worker、文件导出 API 和内存日志性能测试。
- 新增 `PToolsLoggingTests` 对内存容量、重要等级保留、多订阅者、丢弃策略、采样策略、脱敏和性能路径进行验证。

## 5.21.2 — 2026-09-22

- 完成日志隐私脱敏、Network 请求/响应头脱敏、背压计数、drop policy、后台 worker、文件导出 API 和内存日志性能测试。
- LocalConsole 与 PTInstruments 接入共享有界内存日志目标，旧公开日志入口进入 5.22.x 收口窗口。

## 5.20.2 — 2026-09-22

- 增加可选 `PTFileLogDestination`、单消费者异步缓冲、32 KB flush、warning/error/fault 优先 flush、5 MB/24 小时轮转和 7 天/7 文件/30 MB 保留策略。
- 增加日志脱敏兜底和 `PToolsLoggingTests`，覆盖等级过滤、分类等级、敏感字段、文件写入和轮转保留边界。

## 5.20.0 — 2026-09-22

- 完成 CocoaLumberjack 使用面审计，记录 DDLog、文件日志、formatter、运行时等级、包装器和公开 API 泄露结果。
- 新增 SwiftPM `PToolsLogging` product/target 与 CocoaPods `PooTools/Logging` subspec，Core 依赖新的日志契约但保留旧日志实现。
- 新增 `PTLogLevel`、`PTLogCategory`、`PTLogRecord`、`PTLogConfiguration`、`PTLogDestination` 和 `PTLogger`，为后续 OSLog、文件日志和 Debug 接入提供 Swift 6 值类型边界。
- 5.20.x 不删除 CocoaLumberjack、不迁移 `PTNSLog` 调用、不修改第三方依赖；这些变更保留到后续里程碑并由审计报告跟踪。

## 5.19.5 — 2026-09-22

- 修复 `PTDarkModeScheduleMonitor` 的系统环境通知回调从后台队列进入 `@MainActor` 时触发的 dispatch 队列断言；通知入口先桥接到 `MainActor`，再刷新暗色模式状态。
- 修复 `PTCollectionView` 在外部设置 `contentInset.top/bottom` 后底部刷新仍保持隐藏的问题；footer 现在按有效可滚动范围重新计算，并继续保持 `verticalScrollIndicatorInsets` 仅影响滚动指示器。

## 5.19.3 — 2026-09-21

- 修复 `PTNavBar` 设置 `titleView` 时覆盖标题容器约束的问题；标题容器现在按整条导航栏居中，并根据较宽的按钮组设置明确可用宽度。

- 修复右侧按钮清空时误隐藏左侧按钮的问题，保证 `PTMediaLibAlbumListViewController.navTitle` 在伪导航栏中保持稳定居中。

## 5.19.2 — 2026-09-21

- 修复 PhotoPicker `PTMediaLibViewController.selectLibButton` 的 bounds 重算和导航栏 `.auto` 标题约束，避免相册标题或下拉图标显示不全。

- 修复 `PTMediaLibAlbumListViewController` 标题视图未居中问题：使用 `.auto` 测量模式、单行截断和稳定的内容优先级，避免标题被左右按钮区域拉伸。

- 清理 Swift 6 并发边界：移除 WebKit 销毁阶段的 MainActor 越界、HealthKit 冗余转换、LAContext/UIImage/CGImage 的不安全 detached 捕获，并用锁保护 Debug 触摸快照。

- 新增并发边界文档和 5.19.2 门禁；保留合法的文件 I/O、纯数据解码、Vision/AVFoundation 系统适配 detached 工作，并明确其快照和所有权边界。

- 新增 `VERSION` 单一版本源，校验 CocoaPods、SwiftPM、Podfile.lock、README、CHANGELOG、ROADMAP 和发布元数据，防止版本漂移。
- 新增 CocoaPods / SwiftPM 包矩阵、直接依赖矩阵、5.18.2 Public API baseline 和 13 个领域测试矩阵。
- 新增 API 删除门禁、命名债务登记和编译宏新旧别名；`drop`、`POOTOOLS_BIOID`、`POOTOOLS_ZIPARCHIVE`、`POOTOOLS_MXMETRICMANAGERKIT` 作为 canonical 入口。
- 补齐 Package、Dependency、Tests、API 和 Documentation 维护入口；第三方依赖版本和 Pods 源码保持不变。

- 新增可复用的 `PTSearchViewController<Item>` 搜索基类，统一 SearchBar、PTCollectionView、状态机、History、Suggestion、Pagination、Refresh、Empty、Error 和生命周期取消。
- 新增 `PooToolsSearch` SwiftPM product 与 `PooTools/Search` CocoaPods subspec；旧 `SearchBar` 继续独立可选安装，避免无搜索需求的宿主增加容器依赖。
- 搜索请求使用 `PTSearchSnapshot` 和集中 `PTSearchTaskCoordinator` 防止旧请求回写新关键词，支持 Local、Remote、Hybrid 和 Custom 四种模式。
- 搜索展示支持 contentTop、navigationBar、navigationBarExpanded 和 custom；导航栏状态通过 `PTSearchPresentationContext` 保存和恢复，iOS 26 使用原生 `UIGlassEffect`，iOS 17–25 使用材质兼容实现。
- 增加 Search SwiftPM/CocoaPods/源码静态契约门禁；不新增 XCTest target，运行时键盘、Dynamic Type、VoiceOver、RTL、Dark Mode 和多 Scene 回归仍需真实宿主验证。
- 新增 `PTDebugHookRegistry`，统一 Debug Collector 和 Core runtime hook 的安装、卸载与状态快照，避免重复安装或不可逆地散落管理。
- PTInstruments 增加磁盘、线程、启动、ViewController 生命周期、Task 和 Signpost 采样入口；补齐 `.pttrace` 导入、只读回放、轨迹对比和实时快照。
- Session 改用有界环形缓冲，Dashboard 以固定节奏批量刷新；Debug 未启用时不创建采样任务、DisplayLink 或高频 observer。
- LocalConsole 改用当前 UIWindowScene 的屏幕与安全区计算，初始化失败安全返回，不影响业务窗口；保留多 Scene、关闭、拖动、键盘和旋转兼容路径。
- 保留既有公开 API、第三方依赖版本和 Pods 源码不变；真实设备 30–60 分钟录制、性能中位数和多 Scene 宿主回归仍是发布前条件。

## 5.19.1 — 2026-09-20

- 发布 PhotoPicker 标题和 `selectLibButton` bounds 修复基线；后续 `5.19.2` 继续处理 Swift 6 并发边界与文档收口。

## 5.18.2 — 2026-09-20

- 发布 5.18.2 正式兼容基线；5.19.x 在此版本上继续进行 Package、Dependency、Tests、Docs 和 API 治理。

## 5.18.1 — 2026-09-20

- 增加可复用 Search 容器、搜索状态机、异步 Provider、历史记录、建议、分页、刷新和多种导航栏展示位置。
- 保留 SearchBar 独立入口，并提供 SwiftPM `PooToolsSearch` 与 CocoaPods `PooTools/Search`。

## 5.18.0 — 2026-09-20

- 完成 Debug / Instruments 的 5.18.0 稳定基线；新增 Hook Registry、环形录制、`.pttrace` 导入回放和多 Scene LocalConsole 生命周期治理。
- 5.18.x 的 Search 兼容演进继续记录在后续开发版本中。

## 5.17.0 — 2026-09-20

- 完成 42 个 UI Components / Utility 模块的逐项结账清单，统一记录依赖、生命周期、测试、示例、文档和 6.0 决策。
- SearchBar 增加可取消防抖、异步搜索取消、加载状态、清空入口、语言刷新和辅助功能状态。
- Loading、HUD 和 TipsView 修复多 Scene 窗口选择、重复展示、空颜色配置、定时器、DisplayLink 和离屏动画生命周期问题。
- WebKit 增加旧导航回调隔离、内容进程终止恢复和外部 scheme 安全处理；Picker、Alert、Scene 和 MainActor canonical contract 纳入质量门禁。
- 保留既有公开 API、第三方依赖版本和 Pods 源码不变；真实宿主与真机 UI/键盘/VoiceOver/Stage Manager 回归继续作为后续验证条件。

## 5.16.0 — 2026-09-20

- 完成 Permission Core 状态统一：新增 `PTPermissionAuthorizationState`，保留旧状态 API，并统一 callback exactly-once 完成语义。
- 修复 Location、Bluetooth、Photos、Notification 和 Face ID 的细分状态丢失，补充定位精度、临时全精度、通知 critical alert 和密码回退入口。
- 修复 PhotoKit 授权回调边界，通知授权改为异步刷新；权限重复请求、系统回调重复或缺失时不会重复执行 completion。
- 为 IAP、NFC、Motion、HealthKit、MetricKit 和 GPS 增加可幂等停止/失效的生命周期入口，清理 observer、delegate、query、session 和待处理回调。
- 继续支持 iOS 17+ / Swift 6+、CocoaPods、SwiftPM 和 Xcode 入口；对应正式 tag 为 `5.16.0`。

## 5.15.0 — 2026-09-20

- 完成 Media 全家桶第一轮收口：MediaCore 增加 `PTMediaAsset`、`PTMediaType`、`PTMediaMetadata`、`PTMediaResource` 和 `PTMediaSource` 值类型契约。
- 增加 `PTImageDownsampler` 与 `PTImageMemoryBudget`，图片和视频封面路径按目标像素解码，避免本地大图先完整读入 `Data`。
- 增加带 Memory/Disk、变体和容量维护的 `PTMediaCache`，视频封面迁移到统一缓存键，区分原图、缩略图、GIF、Live Photo 和视频帧。
- 视频缓存增加并发下载去重、Range 续传、`.part` 临时文件和原子提交；MediaViewer Cell 与 VideoEditor 增加统一媒体资源失效入口。
- 保留 ImagePicker、PhotoPicker、MediaViewer、ImageEditor、VideoEditor、LivePhoto、PDF、SVG、QRCode 和 SmartScreenshot 的现有公开入口，继续支持 iOS 17+ / Swift 6+。

## 5.14.0 — 2026-09-20

- Network 增加统一的 `PTNetworkRequest`、`PTNetworkExecutor`、类型化响应、请求上下文和错误分类入口。
- 补齐指数退避、抖动、Retry-After、幂等请求保护、缓存过期/ETag/Last-Modified/304、缓存损坏恢复、请求去重和认证刷新合并。
- SocketKit 增加 actor 隔离的 `PTWebSocketClient`，支持连接状态、发送队列上限、取消、心跳超时、网络恢复和前后台生命周期。
- Security 增加不暴露第三方类型的 `PTSecurity`，统一 Keychain、CryptoKit 摘要、HMAC、AES-GCM、P-256 签名和验签入口。
- 保留旧 Network、SocketRocket、DataEncrypt、KeyChain 和 SecuritySuite 公开入口，继续支持 iOS 17+ / Swift 6+。

## 5.13.0 — 2026-09-20

- 完成 UIFoundation、Navigation、Tabbar 和 Collection 的 5.13.x 治理，统一安全区、Scene、Dynamic Type、辅助功能和减弱动态效果边界。
- 修复多层 push/pop、交互式返回、旋转、分屏和台前调度下导航栏与自定义 Tabbar 状态被旧转场覆盖的问题。
- 增加 Tabbar 局部刷新、本地化刷新和布局失效入口，Lottie 加载增加取消与 generation 保护。
- 增加 CollectionView Diffable 快照串行保护、稳定身份校验和 Cell 异步任务复用清理能力。
- 继续保持 iOS 17+ / Swift 6+ 与 5.x 公开 API 兼容。

## 5.12.1 — 2026-09-20

- 同步 5.12.x Core / Foundation 稳定基线，修复版本元数据和构建入口一致性问题。

## 5.12.0 — 2026-09-20

- 收口 `PToolsCore` 的 Foundation-only 边界，新增 `PTLocked`、`PTAtomic`、取消/生命周期/任务存储、MainActor 调度、缓存、日志和基础错误契约。
- 增加 `PTResult` 与 `PTJSONValue` 类型化基础能力，避免动态 `Any` 进入 Core 并发边界。
- CocoaPods `Core` 与 SwiftPM `ptools` 统一复用 `PToolsCore`，保留旧入口兼容，不迁移 UIKit、媒体和业务实现。
- 增加 Core 依赖方向与第三方边界检查，避免 Foundation-only Core 引入 UIKit、Network、Media、Debug 或第三方实现。
- 继续保持 iOS 17+ / Swift 6+，并保留 5.x 兼容 API。

所有正式版本均以同名 Git tag 为准。没有 tag 的开发阶段不会在这里伪装成正式发布版本；构建、
性能和迁移事实见 `report/`，当前计划见 [ROADMAP.md](ROADMAP.md)。

## 5.11.17 — 2026-09-20

- 发布 5.11.x 最后一个正式兼容基线；5.12.0 的 Core / Foundation 解耦在此版本之上继续演进。

## 5.11.14 — 2026-09-17

- 发布当前 5.11.x 版本，完成 Base 导航兼容修复和 CocoaPods 版本基线同步。
- 后续架构收口、依赖 parity 和 6.0 迁移验证继续记录在 Unreleased 与 `report/`。

## 5.11.11 — 2026-09-14

- 发布当前 5.11.x 正式基线，包含 Debug Foundation、PTInstruments 和长期文档结构治理。
- 5.11.x 后续的架构收口、依赖 parity 和 6.0 迁移验证继续记录在 Unreleased 与 `report/`。

## 5.9.9 — 2026-09-12

- 完成进入 Debug Foundation 前的 API、依赖、并发、生命周期、性能和迁移基线。
- 保留 5.x 公开 API 与兼容包装器，不提前删除 deprecated 入口。

## 5.9.7 — 2026-09-11

- 完善 Core、Network、Media、Permission、Navigation、Debug 的模块安装说明和迁移配方。
- 建立 Example 页面索引与真实宿主迁移边界说明。

## 5.9.6 — 2026-09-10

- 建立 Swift 6 并发、依赖供应链、质量门禁和 6.0 迁移基线。
- 统一 canonical API 与旧拼写/动态入口的兼容策略。

## 5.9.0、5.9.2–5.9.5 — 2026-09-09 至 2026-09-10

- 完成 API Freeze、Concurrency、Quality、Lifecycle、Performance 和 UI Quality 系列治理切片。
- 相关扫描结果保留在 `report/baselines/5.9/`，不把一次性结果混入长期架构文档。

## 5.8.9 — 2026-09-09

- 建立 Core / UIFoundation / Permission 分层后的稳定基线。

## 5.7.0–5.7.9 — 2026-09-02 至 2026-09-09

- 增加 `PTListViewController`，统一类表格和类集合列表入口。
- 完成 Picker 嵌入、Alert 长按钮布局、Core 基类、圆角和多 Scene 导航相关治理。

## 5.6.0–5.6.10 — 2026-08-29 至 2026-09-01

- 完成 Core source contract、重复入口、Language、ScreenShot、MessageKit、Button、ImagePicker、
  PhotoPicker、ImageEditor、ScrollBanner 和 PageControl 等模块治理。
- 增加 String Catalog、媒体请求取消、稳定 Diffable ID 和统一图片/视频处理入口。

## 5.0.0–5.5.0 — 2026-08-28 至 2026-08-29

- 完成 5.x Core 基础升级、Swift 6 并发边界、Base/Category 统一以及网络、媒体、路由和调试入口治理。

## 4.x

4.x 的完整逐版本变更由对应 Git tags 保存。5.x 迁移说明见
[`docs/migration/MIGRATION_6.md`](docs/migration/MIGRATION_6.md)。

## Published tags

当前已确认的 5.x 正式 tags：

```text
5.0.0  5.0.1  5.1.0  5.1.1  5.2.0  5.3.0  5.4.0  5.5.0
5.6.0  5.6.1  5.6.2  5.6.3  5.6.4  5.6.5  5.6.6  5.6.7  5.6.8  5.6.9  5.6.10
5.7.0  5.7.1  5.7.2  5.7.3  5.7.4  5.7.5  5.7.6  5.7.7  5.7.8  5.7.9
5.8.9  5.9.0  5.9.2  5.9.3  5.9.4  5.9.5  5.9.6  5.9.7  5.9.9
5.11.11  5.11.12  5.11.13  5.11.14  5.11.16  5.11.17  5.12.1  5.13.0  5.14.0  5.15.0  5.16.0  5.17.0  5.18.0  5.18.2  5.19.1  5.19.2
```

`5.9.1`、`5.9.8`、所有 `5.10.x`、`5.11.0`、`5.11.1` 和 `5.11.15` 当前没有对应 Git tag，
因此不作为已发布版本列出；`5.19.3` 当前仍是开发基线。
