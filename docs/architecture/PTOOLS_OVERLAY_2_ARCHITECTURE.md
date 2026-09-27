# PTools OverlayCore 2.0

## 边界

5.31.0 在 5.29.0 的 OverlayCore 1.0 上增量扩展，不重新创建 Scene Resolver、Window、Host、Registry 或 Z-order。Banner 继续只使用它需要的基础能力；Popover、Tips、Alert 和 ActionSheet 通过产品层表达各自语义。

## 分层

```text
PToolsOverlay
├── Scene / Host / Window / Passthrough
├── Registry / Z-order / Lifecycle / Transition
├── Anchor / AnchorRegistry / Tracking
├── Positioning / Collision / Arrow
├── OutsideTap / ExcludedRegion / Gesture
└── Keyboard / Focus / Accessibility

PooToolsBanner       transient queue and stack
PooToolsTipsView     lightweight anchored explanation
PooToolsPopover      custom anchored content and menu
ActionsheetAndAlert  modal decision and action semantics
```

## 关键约束

- UIKit 对象只在 `@MainActor` 路径中使用，不通过 `@unchecked Sendable` 跨 actor。
- Geometry 输入输出保持值类型，UIKit apply 在 MainActor 完成。
- Anchor 默认由 View 自动转换到 Window 坐标；业务不再手算 Window frame。
- `PTAnchorRegistry` 只保存弱引用，Cell reuse 必须同时校验 View identity 和业务 ID。
- Banner 不被强制引入 Anchor、Arrow 或 Popover 依赖。
- Alert/ActionSheet 不变成 Popover style，只复用 Overlay presentation primitive。

## 失败处理

Anchor 不在 Window、Scene 不可用或 Host 创建失败时返回失败结果，不随机选择其他 Scene，也不使用强制解包。

