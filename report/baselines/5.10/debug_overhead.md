# PTools 5.10.x Debug Overhead Baseline

状态：基线方法已建立，当前工作树尚未采集真实设备 Instruments 数值。

## 关注指标

- Core 无 Debug 产品时：不安装 Debug adapter，不创建 Debug window，不启动 Collector。
- Debug 控制台隐藏时：不向不可见 console 写入 UI buffer；日志 sink 可被移除。
- Debug 控制台显示时：stdout/stderr、网络状态和生命周期采集由独立 Collector 管理，重复 start 不重复安装 hook。
- 多 Scene：每个 console 只持有自己的 sink 和 owner，关闭一个 scene 不会重复停止或重启其他 Collector。
- 日志事件：只跨 actor 传递 `PTLogEvent` 的 String/enum 值快照，不传递 UIKit 或 `Any`。

## 采集方法

在同一台设备、同一构建配置和同一页面操作脚本下，对以下四种状态分别记录 CPU、内存、主线程时间和日志吞吐：

1. Core only / Debug product absent。
2. Debug product present but console hidden。
3. 一个 Scene 显示控制台。
4. 两个 Scene 同时显示控制台。

每种状态至少重复 5 次，记录中位数和峰值；不要把 Simulator 数值当作设备发布预算。

## 当前证据

- `PToolsCore` SwiftPM 目标构建通过。
- `PooTools-Example` Debug / Release iOS Simulator 完整 Xcode 构建通过。
- 静态 Core→Debug 反向引用、依赖方向和 Swift 6 安全门禁通过。
- 真机 CPU/内存/启动耗时和 Debug disabled/enabled 差异尚未测量，因此本文件不声明性能达标。
