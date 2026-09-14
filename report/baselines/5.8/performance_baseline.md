# PTools 5.8 性能基线

## 基线性质

这是源码和配置层面的可重复基线，不是 Instruments、真机或生产压测结果。5.8.9 的真实性能结论必须由宿主项目在目标设备上补充。

## 当前静态指标

- SwiftPM target：81。
- CocoaPods subspec：96。
- Core 直接第三方依赖：18。
- `PTCollectionView.swift`：当前仍为 legacy facade，超过 2000 行，已登记架构例外。
- `Network.swift`：当前约 1900 行，列入 coordinator 拆分计划。
- `PTLRUCache`：已从 CollectionView 主文件移到类型文件，减少 facade 顶部职责。
- Skeleton：使用布局签名缓存、单一 shimmer 动画，并在离开 window 时停止动画。
- Video thumbnail：按 URL、帧号、尺寸和变换策略生成稳定缓存键，并复用统一缩略图服务。
- Network 日志：Release 隐藏完整参数和响应体，敏感请求头不输出原值。

## 必测场景

- PhotoPicker / MediaViewer 快速滚动、请求取消和大图释放。
- Network duplicate、cache、retry、download cancellation 和大响应日志。
- CollectionView 增量更新、Skeleton 重复显示隐藏、旋转和离屏。
- VideoEditor 导出成功、取消、失败和保存失败。

只有在宿主应用完成 Instruments 或等价设备测量后，才能填写帧率、峰值内存、网络耗时和包体变化；本文件的静态数字不替代那些测量。
