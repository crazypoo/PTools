# P1 Architecture Closure

这份记录对应 `PTools_Pre6_Architecture_Closure_Plan.md` 的 H–P 阶段。P1 的代码改动以小步、兼容和可验证为原则；不能由静态检查证明的多场景、视觉和长时间运行结果，单独列为人工验收项。

## 已落地的代码边界

- H：`PTSceneContext.Scope` 提供稳定的场景值标识；Alert、Navigation、Rotation 保留 `.shared` 兼容入口，同时开放实例初始化。
- I：`PTCollectionLayoutCacheCoordinator` 接管高度和 section layout 缓存；`PTCollectionScrollObserverMultiplexer` 接管内部滚动观察者；公开 `PTCollectionView` 门面不变。
- J：`PTTabBarLayoutAppearance` 被 `PTTabBarAppearance` 捕获；`PTTabBarView` 的运行时布局、材质和角标参数读取快照，不再读取可变旧配置。
- K：`PTNavigationConfigurable` 让非 `PTBaseViewController` 页面也能接入自定义导航栏；基类继续作为兼容实现。
- L：`PTSwizzleRegistry.registeredRecords()` 保存 target、selector、owner 和 class-method 信息，供重复注册和隐私审计使用。
- M：保留已有 SwiftPM 质量 targets，并新增独立基础模块契约门禁；本轮不新增测试 target。
- N：新增公开 API 意图登记，和已有源码公开 API inventory 一起作为迁移审计入口。
- O：新增无 branch dependency、固定版本/ revision 和依赖文档门禁。
- P：新增大文件与缓存 ownership registry，记录线程、容量和清理策略。

## 仍需真实宿主或设备验收

- 两个以上 `UIWindowScene` 同时展示 Alert、Navigation、TabBar 和 Rotation 状态。
- `PTCollectionView` 的复杂布局、刷新、拖拽、索引、骨架和快速滚动回归。
- Debug 关闭状态开销、PTInstruments 5/15/30 分钟长会话、导出脱敏和真实宿主回归。
- iOS 17 / iOS 26 / iOS 27、浅色/深色、动态字体、VoiceOver、减少动态效果、分屏和横竖屏矩阵。
- CocoaPods 与 Xcode 工程中的真实依赖图和 Archive 产物。

## 门禁

```text
Scripts/validate_p1_architecture_closure.sh
Scripts/validate_p1_standalone_modules.sh
Scripts/validate_p1_public_api_intent.sh
Scripts/validate_p1_performance_registry.sh
Scripts/validate_p1_dependency_supply_chain.sh
```

这些门禁证明源码契约和静态边界，不代替 Xcode 编译、真实设备或多场景人工验证。

## 本轮验证记录

- `PooTools` Debug、`PooTools-Example` Debug/Release 均已实际发起 Xcode Simulator 构建。
- 三次构建都在外部 `Pods/Harbeth` 的 Metal 编译阶段被同一环境问题阻断：当前 Xcode 缺少 Metal Toolchain，提示使用 `xcodebuild -downloadComponent MetalToolchain`。
- 构建日志未出现 `PooToolsSource` 的 Swift/Clang 源码诊断；因此本轮不能把构建结果标记为成功，也不把 Pods 的阻断归因于 PTools 源码。
- 代码前端解析、SwiftPM manifest、三套构建契约、质量扫描、发布元数据和 P1 静态架构门禁均已通过。
