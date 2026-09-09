# PTools 5.9.x 性能基线

本文件记录静态和实现级基线，不把源码扫描结果当作 Instruments 或真实设备性能结论。

## 已建立的限制

| 资源 | 当前策略 | 目的 |
| --- | --- | --- |
| NetworkCache 内存缓存 | countLimit 200，totalCostLimit 50 MB | 防止大响应无限增长 |
| PTVideoCoverCache | countLimit 100，totalCostLimit 50 MB | 限制视频封面峰值 |
| URLCache | memory 20 MB，disk 100 MB | 复用系统网络缓存 |
| PTCollectionView 骨架 | 路径签名缓存、单一 shimmer | 减少布局和动画重复 |
| PhotoKit 请求 | canonical 请求/取消/generation | 避免复用 Cell 回写旧资源 |

## 盘点报告

- report/cache_inventory_5_9.md：缓存位置、类型和代码行。
- report/singletons_5_9.md：单例声明和共享调用现状。
- report/concurrency_5_9.md：Swift 6 并发敏感操作现状。
- report/accessibility_5_9.md：Dynamic Type、Reduce Motion、Reduce Transparency 扫描。

## 需要 Instruments 或真机验证的项目

- PhotoPicker 快速滚动时的峰值内存和请求取消耗时。
- Network 大响应、缓存清理和去重命中率。
- VideoEditor 导出期间的内存峰值、取消延迟和临时文件回收。
- CollectionView 增量刷新和布局重算耗时。
- 图片/GIF 解码峰值和后台任务占用。

在上述数据完成前，不宣称 5.9.x 达到性能提升或真机稳定性验收。
