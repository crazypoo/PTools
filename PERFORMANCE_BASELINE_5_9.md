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

## 5.9.2 基准夹具

| 模块 | 已建立夹具 | 尚需实测 |
| --- | --- | --- |
| Collection | 1k/10k 全量快照、增量追加、快速稳定 ID 更新 | 主线程耗时、布局旋转、瀑布流、Photo 预取、分配次数 |
| Network | 100 并发相同请求的去重、稳定请求键构造 | cache hit/miss、retry、大下载、取消、真实吞吐 |
| Media | 4K 图片缩略图准备、视频帧请求和缓存键 | 冷热缓存、快速复用、视频 prepare、内存警告 |
| Navigation | 多容器栈操作和 interactive-pop 入口 | 交互取消、转场耗时、TabBar 隐藏/恢复 |

基准测试使用 XCTest `measure` 记录相对变化，不在代码中写死跨机器阈值。最终的主线程时长、内存峰值和 allocations 必须从 iOS Simulator/真机及 Instruments 记录，不能用 macOS 主机结果替代。

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
