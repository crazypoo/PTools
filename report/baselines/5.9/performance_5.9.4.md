# PTools 5.9.4 Performance / Memory / Cache 实施报告

实施日期：2026-09-10（北京时间）

本报告记录代码层性能治理和可复核的静态结果。Xcode workspace 构建仍被外部 Pods
阻断，因此不把本报告当作真机或 Instruments 验收结论。

## 已实施内容

### 缓存边界

| 缓存 | 所有者与线程边界 | 容量策略 | 清理策略 |
| --- | --- | --- | --- |
| `NetworkCache` | actor `NetworkCache` | 内存最多 200 项、50 MB；磁盘使用现有配置上限 | 磁盘维护使用文件元数据按最旧优先淘汰，避免读取完整响应体；清理按时间节流 |
| `PTVideoCoverCache` | `@MainActor`；磁盘存储为 actor | 内存最多 100 张、50 MB；磁盘上限 100 MB，回收目标 70 MB | JPEG 原子写入；按文件大小和修改时间淘汰；内存告警释放内存缓存并取消未完成封面任务 |
| `PTAudioService.durationCache` | `@MainActor` | 最多 256 项，按 `Float` 成本限制 | 内存告警释放派生时长；音频文件仍保留在磁盘缓存中 |
| `PTCollectionView` 布局缓存 | `@MainActor` | 高度缓存最多 1000 项，布局缓存使用既有上限，瀑布流缓存最多 50 项 | 内存告警清空布局、瀑布流和回退高度缓存 |
| Kingfisher 图片缓存 | Kingfisher 的内存/磁盘缓存策略 | 继续使用现有库策略，不新增第二套图片缓存 | 交由 Kingfisher 处理内存告警；PTools 不重复持有同一份大图 |

缓存盘点明细见 `report/cache_inventory_5_9.md` 和
`report/cache_inventory_5_9.json`。本次还将网络磁盘清理改为仅读取文件元数据，避免维护操作
反序列化可能很大的缓存响应。

### MainActor 重任务审查

- `PTLoadImageFunction` 的 Data、GIF 和本地文件解码继续放在后台任务；结果应用回 UI 时回到 MainActor。
- `PTVideoThumbnailService` 使用 AVFoundation 异步加载，图片结果只在 UI 边界使用。
- `NetworkCache` 的响应缓存维护在 actor 和后台任务中执行，成功请求不新增完整 JSON 输出。
- 本批没有把后台任务机械改成 `Task.detached`，避免把 UIKit、PhotoKit 和 AVFoundation 对象越过其安全边界。

### 布局重复工作

- `PTNavBar` 以容器宽度、左右按钮宽度、间距和默认边距组成几何签名；签名不变时不再重复重建标题容器约束。
- `PTNavBar` 使用实际容器宽度计算标题最大宽度，旋转或多窗口尺寸变化时可以重新计算。
- `PTTabBarView` 在高亮渐变边界未变化时不重复写入图层 frame。
- `PTTabBarView` 的选中遮罩在布局回调中不再递归触发 `layoutIfNeeded()`，并且 frame / 圆角未变化时直接返回。
- 现有骨架、装饰、弹窗和列表布局缓存继续复用，不改变 Diffable snapshot 或公开 API。

### 内存告警

新增 `PTMemoryWarningCoordinator`，统一监听 UIKit 内存告警并在 MainActor 中通知短生命周期缓存。
目前接入列表布局缓存、视频封面内存缓存/待处理任务和音频时长缓存；磁盘媒体文件不因内存告警被误删。

## 验证结果

| 项目 | 结果 |
| --- | --- |
| 修改文件 Swift 前端语法解析 | 通过 |
| `swift package dump-package` | 通过 |
| `git diff --check` | 通过 |
| 质量扫描 | 通过；`Network.swift` 已收敛至 1999 行 |
| Xcode Debug workspace 构建 | 外部 `Pods/KituraContracts` Swift 6 并发错误阻断 |
| Xcode Release workspace 构建 | 外部 `SmartCodable` 宏脚本无法获取 `swift-syntax` 阻断 |
| PooToolsSource 构建诊断 | 两份日志均未出现 PooToolsSource warning/error |

Xcode 原始日志：

- `/tmp/ptools-594-batch3-debug.log`
- `/tmp/ptools-594-batch3-release.log`

仍需在外部 Pods 阻断解除后执行真实宿主、真机和 Instruments 验证，重点测量图片解码、视频缩略图、
网络缓存维护、列表滚动、布局次数和内存告警后的恢复行为。
