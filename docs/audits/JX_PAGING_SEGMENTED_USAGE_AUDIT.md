# JX Paging / Segmented 使用审计

> 版本：5.30.0

## 结论

本次审计以当前仓库源码为准，扫描 `Package.swift`、`PooTools.podspec`、`PooToolsSource`、`Sources` 和 `Tests`。旧的 JX 实现只存在于 `SegmentControl` 的四个兼容文件中，没有发现 PTools 生产代码或示例工程直接调用 JX 类型，也没有发现公开 API 暴露 JX 类型。

## 旧实现分类

| 位置 | 原用途 | 分类 | 处理结果 |
| --- | --- | --- | --- |
| `PTMainSegmentCell.swift` | 分段 Cell | J. 自定义 Cell | 改为原生 `UICollectionViewCell`，保留兼容字段 |
| `PTMainSegmentDataSource.swift` | 标题/图片数据源 | J. DataSource / Model | 改为 `PTSegmentItem` 适配器 |
| `PTMainSegmentModel.swift` | 分段模型 | J. ItemModel | 保留为弃用兼容模型，不再依赖 JX |
| `PTSegmentControlBaseModel.swift` | 基础配置模型 | J. ItemModel | 保留为弃用兼容模型，不再依赖 JX |

未发现以下业务场景的活动调用点：

- `Segmented + 自定义 ListContainer`
- `Segmented + JXPagingView`
- 独立 `JXPagingView`
- Nested Paging
- Header Stretch / Refresh / Navigation Gesture 的 JX 专用扩展
- 自定义 JX Indicator

## 5.30.0 迁移判断

- `PTSegmentedView`、`PTPageContainer` 和 `PTPagingView` 是新的唯一实现入口。
- 旧兼容模型只负责帮助旧调用方过渡，不提供 JX 类型别名，也不要求业务继续导入 JX 库。
- 文档和迁移说明可以出现历史 JX 名称；交付源码由 `Scripts/CI/check_jx_paging_removed.sh` 单独门禁。
- 真实宿主项目仍需验证页面视觉、复杂嵌套滚动、刷新控件和自定义 Header 交互；本审计不把静态扫描或编译结果当作真机行为证明。

## 审计命令

```bash
bash Scripts/CI/check_jx_paging_removed.sh
```

脚本只扫描交付源码，避免迁移文档和历史 Changelog 中的说明文字误报。
