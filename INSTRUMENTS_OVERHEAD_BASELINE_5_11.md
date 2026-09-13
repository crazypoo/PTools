# PTools 5.11.x PTInstruments 开销基线

状态：采样链路、上限和门禁已建立；当前工作树尚未采集真实设备的最终数值。

## 必须对比的四种状态

| 状态 | 预期 | 当前证据 | 最终状态 |
| --- | --- | --- | --- |
| Debug product absent | 不创建 PTInstruments、Collector 或 Debug UI | 源码入口为显式调用 | 待真实宿主确认 |
| Debug present / recorder stopped | 不创建后台采样 Task、DisplayLink 或 observer | 静态门禁通过 | 待真机确认 |
| Recording enabled | 仅启动所选 Instrument，按 policy 采样 | actor、取消和数量上限已实现 | 待真机测量 |
| Timeline UI open | 只渲染已有 snapshot，不增加采集源 | UI 为 snapshot 适配器 | 待真机测量 |

## 采集方法

在同一台真实设备、同一 Debug 构建和同一页面操作脚本下，分别执行上表四种状态。每种状态
至少重复 5 次，记录启动耗时、平均/峰值 CPU、常驻内存、主线程卡顿、FPS 和日志吞吐，使用
中位数与峰值进行比较。Simulator 数据只用于功能回归，不用于发布性能预算。

建议至少覆盖：

- `PooTools-Example`。
- `CrazyDashboard` 或一个实际宿主工程。
- iOS 17 设备与当前最新系统设备。
- Portrait、Landscape、Split View 和多 Scene。
- Light/Dark、Reduce Motion、Reduce Transparency。
- 5 分钟录制、快速 start/stop、空数据和接近采样上限的会话。

## 开销控制点

- FPS 使用一个 DisplayLink，且使用活动屏幕的 `maximumFramesPerSecond`。
- CPU、Memory 和 Stall sampler 都有取消路径；停止时解除 Task 和 observer。
- Session actor 承担唯一可变存储，超过上限只增加 dropped count，不无限增长数组。
- 日志、网络和导出只传递 String/数字/枚举快照；导出不保存完整响应体和敏感请求头。
- 5.11 不设置缺乏实测依据的 CPU 百分比目标，发布预算应以本文件实测结果冻结。

## 发布门槛

在真实设备和真实宿主结果补齐前，只能称为“实现和静态验证完成”，不能称为
`PTInstruments` 性能验收通过，也不能完成 5.11.8/5.11.9 的最终基线或 6.0 rehearsal。
