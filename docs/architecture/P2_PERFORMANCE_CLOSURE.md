# P2 Performance / Cache / Large-file Closure

对应 `PTools_Pre6_Architecture_Closure_Plan.md` 的 Phase P（PERF-P01～PERF-P04）。本轮保持 iOS 17+、Swift 6+ 和现有公开 API 不变。

## 已实施

### PERF-P01：缓存盘点

- `Scripts/p1_performance_registry.json` 升级为 schema 2。
- 每个登记缓存都记录 owner、storage、thread、count limit、cost limit、disk limit、eviction 和 memory warning。
- `Scripts/report_cache_inventory_5_9.rb` 继续生成完整源码盘点；登记表用于明确责任和容量契约。
- `Scripts/validate_p1_performance_registry.sh` 现在会校验缓存字段、大文件状态和已拆出的文件是否真实存在。

仍需后续处理的缓存已经明确标记为 `not configured` 或 `follow-up required`，不把“已盘点”误报成“已优化”。

### PERF-P02：MainActor 重活

- `PTVideoCoverCache` 的缓存图片解码和 JPEG 编码通过 utility detached task 执行，磁盘读写继续由 actor 管理。
- `PTVideoThumbnailService` 使用窄范围 `PTVideoAssetSendableBox` 传递 AVFoundation 系统对象；帧时间计算和 `AVAssetImageGenerator` 生成在 detached task 中执行，UI 回调仍回到 MainActor。
- 新增 `Scripts/report_mainactor_heavy_work.rb`，用于定位图片解码、视频缩略图、文件 I/O、JSON 和大数据转换。
- 报告中的 `review-required` 只代表需要 Instruments 或宿主场景确认，不代表源码自动通过运行时性能验收。

### PERF-P03：大文件收口

- `PTBaseViewController.swift` 已移出 `PTNavigationBarManager.swift`。
- `PTCollectionView.swift` 已移出 `PTCollectionViewSkeleton.swift`，并复用已有的 `PTCollectionViewTypes.swift`。
- `Network.swift` 已移出 `Network+Download.swift` 和 `Network+Logging.swift`。
- 旧公开入口、方法签名和兼容行为保持不变。
- `PTCollectionView` 仍登记为 active legacy facade；后续只按 coordinator 边界继续拆分，不扩大 private 状态可见性。

### PERF-P04：例外责任

- `Scripts/file_size_allowlist.txt` 继续登记硬性大文件例外的 ticket、原因和责任边界。
- `Scripts/p1_performance_registry.json` 为每个大文件补充 status 与 extracted_files。
- `Scripts/validate_p2_performance_closure.sh` 检查新文件的 Xcode 引用数量，防止重复 Compile Sources 条目重新出现。

## 门禁

```text
Scripts/validate_p2_performance_closure.sh
Scripts/validate_p1_performance_registry.sh
Scripts/report_cache_inventory_5_9.rb
Scripts/report_mainactor_heavy_work.rb
Scripts/validate_file_size_gate.sh
```

这些脚本只证明静态契约和登记完整性；完整的 Xcode 构建、Instruments、内存警告和真实媒体场景仍需单独验证。

## 未伪装为完成的项目

- PDF、GIF、音频文件和 debug URLCache 的长期磁盘容量仍需要独立策略，本轮已登记但没有擅自改变其公开行为。
- `PTCollectionView` 的剩余刷新、布局和分页逻辑尚未整体重写。
- 如果 Xcode 缺少 Metal Toolchain 或外部 Pods 失败，构建结果必须记录为环境阻断，不能归因给 PTools 源码通过。
