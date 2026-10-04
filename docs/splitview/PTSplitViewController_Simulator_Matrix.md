# PTSplitViewController 模拟器验证矩阵

本矩阵用于验证 PTools 5.61.0 的 `PTSplitViewController` 和 `navigation.split-view` Demo。实现只依赖 UIKit 的 compact / regular size class，不根据设备型号或屏幕宽度写分支。

## 需要覆盖的窗口

| 窗口 | 重点验证 |
| --- | --- |
| iPhone 小尺寸竖屏 | Demo 可打开、Category → Component → Detail、返回和状态恢复 |
| iPhone Pro 竖屏 | compact push 使用当前可见导航栈，不进入隐藏 secondary |
| iPhone Pro 横屏 | compact / regular 变化时 detail、Router 和选中状态保持一致 |
| iPhone Pro Max 竖屏 | 长列表、关闭入口和 Inspector 兼容回退 |
| iPhone Pro Max 横屏 | 旋转后 compact / regular 切换和可见导航栈 |
| iPad 竖屏 | double / triple column、supplementary 和 secondary 更新 |
| iPad 横屏 | triple column、Inspector、Router 和 State Restore |
| Resizable iPad Simulator Window | 连续调整窗口宽度时不丢失当前 detail 和选择状态 |

## 每个窗口的最小流程

1. 从 Demo Catalog 打开 `Adaptive SplitView — iPhone / iPad`。
2. 在 compact 窗口依次选择 Category、Component 和 Detail，确认 detail 被推入当前可见导航控制器。
3. 在 regular 窗口确认 primary、supplementary、secondary 三列联动，且 Router 不把 SplitView 推入外层导航栈。
4. 执行 Save State、Reset、Restore State，确认稳定 ID 和当前列状态恢复。
5. 打开和关闭 Inspector，确认 iOS 26+ 使用原生 Inspector，其他系统使用 page sheet 回退。
6. 旋转或调整窗口尺寸，确认当前 detail、选中项和导航深度不被清空。

## 证据边界

构建、静态回归脚本和组件测试只能证明代码契约；实际窗口布局、动画、Stage Manager、多 Scene 和外接屏仍需要在对应 Simulator 或真实 Host 上人工确认。Stage Manager、多个 Scene 和外接屏不作为本轮自动化门禁。

## 本轮已获得的证据

- Xcode workspace Debug 构建通过。
- Xcode workspace Release 构建通过。
- iPhone 17 Simulator 安装并启动通过。
- iPad Pro 11-inch Simulator 安装并启动通过。

启动冒烟不等同于完成每个窗口的交互和视觉验收；Category → Component → Detail、Inspector、旋转和可调整窗口仍应由宿主项目按上表逐项人工确认。
