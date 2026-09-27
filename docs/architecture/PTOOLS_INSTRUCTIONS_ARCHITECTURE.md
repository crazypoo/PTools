# PooToolsInstructions 架构

## 边界

`PooToolsInstructions` 是 UIKit 引导层，依赖现有 `PToolsOverlay`，不创建第二套 Window、Scene、Anchor 或箭头定位引擎。

```text
PTInstructionCenter
        ↓
PTInstructionCoordinator（MainActor 状态机）
        ↓
PTOverlayHost / PTAnchorResolver / PTPopoverPositioningEngine
        ↓
PTInstructionMaskView + PTInstructionCardView
```

## 并发规则

- UIKit、Overlay、目标注册和生命周期统一在 `MainActor`。
- Tour、Step 的业务 ID 和进度快照使用不可变值类型。
- 条件和生命周期 Hook 使用 `@MainActor @Sendable`。
- 不使用 `Task.detached`、全局可变共享状态或 `@unchecked Sendable`。
- UserDefaults 存储由 `PTInstructionStore` 的 MainActor 边界保护。

## 目标与交互

目标可以是 UIView、现有 `PTAnchor`、注册 ID 或多个 Anchor。目标等待、滚动揭示、镂空触控转发、目标点击、覆盖层点击、按钮推进和取消都由协调器统一处理。

## 版本边界

5.32.0 先完成稳定的 P0/P1 原生核心；复杂业务内容、指标后端和跨应用教程不在本版本新增，避免复制 Overlay 基建。
