# 教育型 UI 组件边界

| 组件 | 语义 | 责任 |
| --- | --- | --- |
| `PooToolsGuide` | onboarding / paging | 多页引导和页面导航 |
| `PooToolsInstructions` | coach mark / walkthrough | 聚焦目标、镂空、推进和持久化 |
| `PooToolsWhatsNewsKit` | release notes | 版本变更和新功能说明 |
| `PooToolsTipsView` | contextual tip | 单次上下文提示 |

这些组件可以复用 Overlay 的 Host、Anchor、定位、生命周期和无障碍基础能力，但不互相复制状态机和 Window。
