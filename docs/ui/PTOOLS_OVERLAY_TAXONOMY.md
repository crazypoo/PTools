# PTools Overlay 组件选择

| 场景 | 组件 |
|---|---|
| 删除确认、强模态决策 | `PTAlert` / `PTAlertManager` |
| 多动作选择 | `PTActionSheet` |
| 指向按钮的简短说明 | `PTTipsView` |
| 按钮旁复杂面板 | `PTPopover` |
| 标准系统菜单 | `UIMenu` / `UIContextMenuInteraction` |
| 高度自定义上下文菜单 | `PTContextMenu` |
| 顶部或底部状态事件 | `PToolsBanner` |
| Loading | HUD / Loading |
| 大型半屏交互 | FloatPanel |
| 新手引导 | Guide |

OverlayCore 是基础设施，不是万能业务组件。产品层应保留各自的队列、模态、菜单和短时提示语义。

