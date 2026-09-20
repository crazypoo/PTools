# PTools 质量与验收方法

## 目标

质量文档描述“如何测”和“什么算通过”；某一次构建、扫描或真机测试的事实结果写入 `report/`，
不在本文件硬编码临时数字。

## 静态门禁

每次修改后执行：

```bash
bash Scripts/validate_docs.sh
bash Scripts/validate_document_versions.sh
bash Scripts/validate_build_entries.sh
bash Scripts/validate_quality_scans.sh
swift package dump-package
git diff --check
```

必要时执行 `pod lib lint PooTools.podspec --allow-warnings --skip-tests`。修改 Swift 文件后先做
前端解析，再做完整 Xcode 构建；语法解析不能替代工程构建。

静态门禁必须覆盖：

- Core 源文件在 CocoaPods、SwiftPM 和 Xcode 中的 membership 一致。
- Core 不直接依赖 Network、Debug UI 或业务模块。
- 新代码不增加未经登记的 `@unchecked Sendable`、`nonisolated(unsafe)`、`try!` 或 `as!`。
- 公开 API baseline、模块图、重复入口和 deprecated inventory 有事实报告。
- 文档根目录、相对链接和版本事实通过文档门禁。

## Build Matrix

| 入口 | 配置 | 目的 |
| --- | --- | --- |
| SwiftPM | Debug / Release，iOS 17+ | target、依赖和 manifest 契约 |
| CocoaPods | Core 与目标 subspec lint | podspec、source、资源和依赖 |
| Xcode | `PooTools-Example` Debug / Release | 工程 membership、链接和完整源码 |
| Xcode | `PooTools` Debug | Core target 的独立构建 |
| Xcode | Simulator / Generic Device | 区分模拟器产物、设备产物和 toolchain 阻断 |

外部 Pods、链接搜索路径、Metal toolchain、签名和依赖产物必须单独分类，不能伪装成 PTools 源码通过。

## Runtime Regression

### Scene / Navigation

- 多 Scene 创建、切换和 disconnect。
- A → B → C push 后，点击返回和 interactive-pop 都恢复上一页导航栏样式。
- Alert、ActionSheet、LocalConsole、Inspector 不抢其他 Scene 的 key window。
- 横竖屏、分屏、刘海和键盘弹出时 safe area 正确。

### List / Media

- CollectionView 快速滚动、预取、骨架、空状态、分页和稳定 Diffable ID。
- ImagePicker 与 PhotoPicker 的取消、无权限、单选、多选、Live Photo 和 iCloud。
- 图片/GIF/视频请求取消后不会回写旧 Cell；媒体保存失败和取消只回调一次。
- VideoEditor 导出成功、取消、失败、保存失败和页面退出都能结束资源生命周期。

### UI / Accessibility

- Light/Dark、Dynamic Type、Reduce Motion、Reduce Transparency 和 VoiceOver。
- Alert 长按钮列表可滚动，取消按钮在底部且只回调一次。
- 自定义圆角在 Auto Layout、Cell 复用和尺寸变化后仍生效。
- PageControl、ScrollBanner、Button 和列表状态切换不重复创建动画或视图。

### Debug / PTInstruments

- Debug disabled 不创建窗口、采样器、DisplayLink、sink 或高频 observer。
- 两个 Scene 同时显示 Console 时，关闭一个不停止另一个的 Collector。
- PTInstrumentRecorder 快速 start/stop、空数据、上限、取消和导出/导入。
- `.pttrace` 不含 query、Authorization、Cookie、Token、密码、响应正文或用户输入。

## Performance Measurement

使用同一设备、同一构建和同一操作脚本，每种状态至少重复五次，记录中位数和峰值：

- CollectionView：1k/10k snapshot、增量刷新、快速滚动、布局旋转和预取。
- Network：dedup、cache hit/miss、过期/304/损坏缓存、retry/Retry-After、幂等 POST、100 并发 401
  刷新、大响应、上传、下载和取消。
- Socket / Security：离线重连、心跳超时、发送队列上限、前后台切换、Keychain accessibility、
  生物识别项目、AES-GCM、HMAC、P-256 签名验签和敏感日志脱敏。
- Media：4K 图片、GIF、视频帧、冷/热缓存、导出和内存警告。
- Media 5.15：`PTImageDownsampler` 目标像素、Memory/Disk 变体键、100+ 媒体快速浏览、视频 Range
  续传、`.part` 清理、编辑导出取消、Live Photo/播放器 observer 释放和低磁盘空间。
- Debug：Core only、Debug hidden、单 Scene recording、双 Scene recording。
- PTInstruments：启动耗时、CPU、内存、FPS、hitch、主线程卡顿、日志吞吐和五分钟长会话。

Simulator 结果只能证明功能回归和构建，不替代真实设备的性能预算。

## Report Ownership

| 结果 | 位置 |
| --- | --- |
| 当前依赖/API/并发/模块扫描 | `report/current/` |
| 发布冻结基线 | `report/baselines/<version>/` |
| 人维护的测试方法 | 本文件 |
| 发布流程 | `docs/maintainers/RELEASE.md` |

自动报告必须包含 `AUTO-GENERATED`、Generator、Source revision 和 Generated at 元数据。
