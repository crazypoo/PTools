# Changelog

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

## Unreleased — 5.13.x UIFoundation / Navigation / Tabbar / Collection

当前 `PooTools.podspec` 为 `5.13.0`，工作树中的后续架构收口尚未作为新版本发布。

- 5.10 Debug Foundation 与 5.11 PTInstruments 已进入当前代码架构，仍需真机、真实宿主和多 Scene 回归。
- 建立长期 `docs/` 文档结构，区分用户指南、当前架构、迁移、维护流程和自动报告。
- 继续冻结 6.0 前的 public API、module graph、deprecated inventory 和性能基线。

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
```

`5.9.1`、`5.9.8`、所有 `5.10.x` 和所有 `5.11.x` 当前没有对应 Git tag，因此不作为已发布版本列出。
