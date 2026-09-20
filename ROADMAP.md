# PTools 路线图

> 当前代码基线：`5.15.0`（来自 `PooTools.podspec`）
>
> 当前最新正式 Git tag：`5.13.0`；`5.15.0` 为当前开发基线，尚未创建正式 tag。

## 范围与约束

PTools 面向 iOS 17+ / Swift 6+。5.x 的主要治理范围是 `PooTools.podspec` 的
`default_subspec = Core` 及其直接扩展边界。公开 API、CocoaPods subspec、SwiftPM product
和第三方依赖在没有迁移证据前保持兼容。

长期规则：

- 当前架构写入 [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md)。
- Debug 与 PTInstruments 设计写入 [`docs/architecture/DEBUG_AND_INSTRUMENTS.md`](docs/architecture/DEBUG_AND_INSTRUMENTS.md)。
- 发布流程写入 [`docs/maintainers/RELEASE.md`](docs/maintainers/RELEASE.md)。
- 测试方法和发布门槛写入 [`docs/maintainers/QUALITY.md`](docs/maintainers/QUALITY.md)。
- 单次扫描、构建和基准结果写入 `report/`，不混入长期架构文档。
- 新版本不再创建 `ARCHITECTURE_5_12.md`、`PERFORMANCE_BASELINE_5_12.md` 等版本化长期文档。

## 5.12.0 Core / Foundation 收口

- ✅ 增加 Foundation-only 的 `PToolsCore` 并发、生命周期、缓存、日志和错误契约。
- ✅ CocoaPods `Core` 依赖并复用 `PToolsCore`，旧 Core 源码通过兼容别名保留公开入口。
- ✅ Core 的 URL 解析、关联对象和模型值类型不再在拆分构建中重复实现。
- ✅ 增加 Core 边界静态门禁，明确第三方适配器不得进入 `PToolsCore`。
- [ ] UIKit、媒体和历史第三方兼容实现继续在后续 5.13–5.15 迁移，不在 5.12.0 直接删除公开入口。

## 5.13.0 UIFoundation / Navigation / Tabbar / Collection

- ✅ UIFoundation 增加安全区、Scene、动态颜色和减弱动态效果的统一上下文辅助能力。
- ✅ Navigation 按具体导航控制器应用导航栏项目，交互式 push/pop 不再依赖跨栈全局控制器状态。
- ✅ Tabbar 增加安全区、旋转、分屏和台前调度后的布局恢复，并过滤过期转场回调。
- ✅ Tabbar 补齐 `reloadData()`、`reloadItem(at:)`、`invalidateLayout()`、`refreshLocalization()` 入口。
- ✅ Lottie 图标增加取消和 generation 校验，避免快速切换后旧动画回写当前 Tab。
- ✅ CollectionView 增加 Diffable 快照串行保护、空 Row 身份校验和 rowCount 安全归一化。
- ✅ 基础 Cell 增加 `PTReusableTaskBag`、`cancelAsyncWork()` 和 `resetContent()` 复用契约。
- ✅ 列表高频 UI 文件继续通过 `PTSceneContext` 解析窗口，兼容多 Scene、分屏和外接显示器。
- ✅ 保持 iOS 17+、Swift 6+ 和现有公开 API 兼容；旧入口继续作为适配层保留。

## 5.14.0 Network / Socket / Security

- ✅ 建立 `PTNetworkRequest`、`PTNetworkResponse` 和 `PTNetworkExecutor` 类型化请求契约，旧动态入口继续停留在兼容层。
- ✅ 统一普通请求、Body、上传/下载生命周期的取消、错误快照、日志脱敏和执行边界。
- ✅ 增加指数退避、抖动、Retry-After、幂等键保护和可重试状态/网络错误策略。
- ✅ 修复请求去重的稳定 key、等待者独立取消和 multipart 兼容边界。
- ✅ 完成缓存策略、过期判断、ETag/Last-Modified、304、`networkElseCache` 和损坏缓存恢复。
- ✅ 增加认证刷新 actor 合并，多个 401 请求只共享一次 token 刷新并各自重放一次。
- ✅ 增加原生 `PTWebSocketClient`，覆盖状态机、队列上限、心跳、超时、网络恢复和前后台生命周期；`PTSocketManager` 保留兼容入口。
- ✅ 增加 `PTSecurity` 原生安全门面，使用 CryptoKit/Security.framework，旧 CryptoSwift、KeyChain 和 SecuritySuite 入口保持兼容。
- ✅ CocoaPods 与 SwiftPM 增加 Security 产品/子模块；不升级第三方依赖，不修改 Pods 源码。
- [ ] 完成真实宿主与真机上的 100 并发 401、断网恢复、WebSocket 服务端心跳和 Keychain 生物识别回归。

## 5.15.0 Media 全家桶

- ✅ MediaCore 增加统一的 `PTMediaAsset`、`PTMediaType`、`PTMediaMetadata`、`PTMediaResource` 和 `PTMediaSource` 值类型，Picker、Viewer、Editor 适配层不再新增重复基础模型。
- ✅ Core 增加 `PTImageDownsampler` 和 `PTImageMemoryBudget`；本地大图、Data 图片和视频封面统一使用 ImageIO 目标像素解码。
- ✅ 增加 `PTMediaCache`，以 Memory/Disk、处理变体、尺寸和帧号组成稳定缓存键，避免原图、缩略图、GIF 与 Live Photo 冲突。
- ✅ `PTVideoFileCache` 增加下载去重、Range 续传、`.part` 临时文件、原子替换和视频磁盘容量维护。
- ✅ MediaViewer Cell 统一复用失效、任务取消、GIF 停止、Live Photo 停止和缩放状态清理；VideoEditor 提供幂等 `invalidate()` 生命周期入口。
- ✅ ImagePicker 继续承担单媒体系统选择，PhotoPicker 继续承担自定义 PhotoKit 多媒体选择；两者保持清晰共存和兼容入口。
- ✅ 更新 Media、Picker、Editor 的迁移、模块和依赖文档；Xcode Simulator Debug/Release 构建作为本版本必要门禁。
- [ ] 在真实设备和独立宿主完成 4K 图片、100+ 媒体快速浏览、Live Photo、iCloud、编辑取消、后台切换和低磁盘空间回归。

## 当前 5.11.x 稳定化

以下工作仍属于当前开发线，完成后是否产生新的 patch 版本由实际 bugfix 和发布需要决定：

- ✅ 文档目录重组完成，根目录只保留入口文档。
- ✅ 生成当前 Public API baseline，并由真实源码 revision 标记。
- ✅ 生成当前 CocoaPods / SwiftPM module graph，并检查 Core 边界。
- [ ] 完成 `PTInstruments` 在真实设备上的 CPU、内存、FPS、主线程卡顿和长会话测量。
- [ ] 完成 Debug 多 Scene、Scene disconnect、分屏、旋转和真实宿主回归。
- [ ] 完成 `PooTools-Example` 与至少一个真实宿主的迁移风险记录。
- [ ] 清理 6.0 deprecated inventory，逐项确认调用方、迁移说明和删除条件。
- [ ] 完成 Debug disabled/enabled 的开销对比，并把结果冻结到 `report/baselines/5.11/`。

已落地能力的实现事实维护在当前架构文档和发布记录中，不在路线图重复展开历史任务。

## 6.0 前置条件

### 模块和架构冻结

- [ ] 冻结 Core、UIFoundation、Permission、Network、Media、Debug 的模块图。
- [ ] 冻结公开 API baseline，并对每个变化完成人工批准。
- [ ] 冻结 legacy wrapper、拼写兼容入口和重复实现的删除清单。
- [ ] 确认 Core 不反向依赖 Debug、业务 UI 或宿主工程。
- [ ] 完成 CocoaPods、SwiftPM、Xcode 三套 source membership 与依赖方向检查。

### 迁移和发布冻结

- [ ] [`docs/migration/MIGRATION_6.md`](docs/migration/MIGRATION_6.md) 覆盖所有待删除入口。
- [ ] `PooTools-Example` 不再调用计划在 6.0 删除的入口。
- [ ] 至少一个真实宿主完成 Core、Network、Media、Navigation、Debug 的迁移演练。
- [ ] 完成 Debug / Release、Simulator、Generic Device、CocoaPods lint 和 SwiftPM 验证。
- [ ] 生产 Core 不隐式创建 Debug UI、采样器、DisplayLink、日志 sink 或诊断 observer。

## 6.0 计划

当上述冻结条件全部满足后：

1. 删除已经经过一个完整 5.x 兼容周期、且没有仓库或宿主调用方的 deprecated API。
2. 删除经过人工批准的拼写错误入口和重复实现，保留必要的兼容适配器。
3. 最终确认 Core、Permission、Network、Media、Debug 的边界和安装文档。
4. 更新 CocoaPods、SwiftPM、Xcode 和 README 的安装示例。
5. 发布 6.0 前完成完整质量矩阵、迁移说明和回滚准备。

## 延期能力

以下能力不作为当前 5.11.x 的发布阻断项：

- 完整 Time Profiler call tree。
- Allocations object graph。
- System / Metal Trace。
- Mach stack unwinding、符号化和 dSYM profiler pipeline。

这些能力会显著扩大运行时风险，只有在有明确产品需求和独立性能预算时再立项。

## 验收入口

```bash
bash Scripts/validate_docs.sh
bash Scripts/validate_document_versions.sh
bash Scripts/validate_build_entries.sh
bash Scripts/validate_quality_scans.sh
git diff --check
```

Xcode、真机、真实宿主和 Instruments 的结果必须分别记录；静态检查或单次编译不能替代运行时验收。
