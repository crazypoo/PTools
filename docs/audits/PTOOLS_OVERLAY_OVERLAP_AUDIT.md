# PTools Overlay 重叠审计

| 能力 | 归属 | 处理 |
|---|---|---|
| Scene Resolver / Window / Host | OverlayCore 1.0 | 继续复用 |
| Registry / Z-order / Lifecycle | OverlayCore 1.0 | 继续复用 |
| Anchor / Tracking | OverlayCore 2.0 | 新增到 Overlay |
| Placement / Collision / Arrow | OverlayCore 2.0 | 纯几何入口 |
| Outside tap / Excluded region | OverlayCore 2.0 | 通过共享容器 hit-test 扩展 |
| Keyboard / Focus | OverlayCore 2.0 | 共享策略和协调器 |
| Queue / Stack / Priority | Banner-only | 不迁移到 Popover |
| Tip 文本和短时展示 | Tips-only | Tips 复用 Anchor/Geometry |
| 复杂自定义内容 / Menu / Replace | Popover-only | PTPopover |
| 强模态决策 | Alert-only | PTAlertManager / PTCustomerAlertController |
| 多动作选择 | ActionSheet-only | PTActionSheetController |
| 顶部 transient 事件 | Banner-only | PToolsBanner |

没有新增 `PTPopoverSceneResolver`、`PTPopoverOverlayWindow`、`PTPopoverRegistry` 或 Banner 专属 Window 基建。

