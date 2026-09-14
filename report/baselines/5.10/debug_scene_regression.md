# PTools 5.10.x Debug Scene 回归记录

| 场景 | 预期 | 当前状态 |
| --- | --- | --- |
| 单 Scene 打开/关闭控制台 | window、sink、collector 成对启动和停止 | 源码已覆盖；Simulator/宿主待回归 |
| 两个 Scene 同时打开控制台 | 各自窗口和 console 状态隔离 | session owner 引用计数已实现；真实回归待执行 |
| 关闭其中一个 Scene | 不停止另一个 Scene 的 Collector | 代码路径已实现；真实回归待执行 |
| Scene disconnect | 清理 window、root controller、sink、observer | 静态清理路径已实现；真实回归待执行 |
| present / sheet / keyboard | 不抢业务 key window，safe area 正常 | 代码保留原兼容入口；宿主回归待执行 |
| 横竖屏、分屏、刘海 | 控制台 frame 和菜单可操作 | 宿主回归待执行 |
| Debug disabled | Core 无 Debug UI 创建和高频采集 | Core 反向引用扫描和 Debug / Release 构建通过；运行时待执行 |

## 手工执行清单

1. 在两个可连接 Scene 中分别显示 `LocalConsole.console(for:)`。
2. 分别关闭一个控制台，确认另一场景仍能接收日志和网络状态。
3. 断开并重新连接 Scene，确认旧窗口、sink、observer 和 root controller 不残留。
4. 在 present、sheet、键盘弹出和横竖屏切换时检查窗口层级、触摸穿透和安全区。

本文件不把静态检查或编译成功当作运行时视觉和生命周期验收。
