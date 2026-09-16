# Changelog

所有正式版本均以同名 Git tag 为准。没有 tag 的开发阶段不会在这里伪装成正式发布版本；构建、
性能和迁移事实见 `report/`，当前计划见 [ROADMAP.md](ROADMAP.md)。

## 5.11.11 — 2026-09-14

- 发布当前 5.11.x 正式基线，包含 Debug Foundation、PTInstruments 和长期文档结构治理。
- 5.11.x 后续的架构收口、依赖 parity 和 6.0 迁移验证继续记录在 Unreleased 与 `report/`。

## Unreleased — 5.11.x architecture closure

当前 `PooTools.podspec` 仍为 `5.11.11`，工作树中的后续架构收口尚未作为新版本发布。

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
