# PTCollectionView Diffable 更新指南

> iOS 17+ / Swift 6

## 中文

`PTCollectionView` 将更新分成三类：结构、内容和布局。内部更新由 `PTCollectionUpdateCoordinator` 在 `MainActor` 上串行执行；快照在操作真正执行时读取，因此连续调用不会因为旧快照或正在执行的动画而丢失。

| 场景 | 推荐 API |
| --- | --- |
| 首次加载或整体替换 | `showCollectionDetail(collectionData:)` |
| Section 结构、Header、Footer 或 Decoration 变化 | `reloadSections(at:)` |
| Row 数量或位置变化 | `insertRows`、`deleteRows`、`insertSection`、`deleteSections` |
| 单个 Cell 内容变化 | `reloadItemContent(at:)` |
| 一个 Section 内多个 Cell 内容变化 | `reloadSectionContent(at:invalidateLayout:)` |
| 可安全使用 Diffable 轻量重配置的内容变化 | `reconfigureSections(at:)` |
| 主题、语言或动态字体影响当前可见 Cell | `reloadVisibleContent()` |
| Cell 类型或复用路径发生变化 | `reloadItemCell(at:)`、`reloadSectionCells(at:)` |
| 用新模型替换一个或多个 Row | `updateRow(_:)`、`updateRows(_:)` |
| 替换 Row 内容并可选使布局失效 | `updateItemContent(at:using:invalidateLayout:)` |
| Section 几何变化 | `invalidateSectionLayout(at:)` |
| 单个 Item 的高度或瀑布流几何变化 | `invalidateItemLayout(at:)` |
| 运行中切换布局类型 | `switchLayout(to:animated:scrollPolicy:completion:)` |
| 运行中修改布局配置 | `updateLayoutConfiguration(animated:scrollPolicy:completion:_:)` |

### 稳定身份

需要增量更新和动画时，必须显式提供稳定的 `PTSection(identifier:)` 和 `PTRows(diffId:)`。`identifier` 与 `diffId` 只表示身份；展示状态、颜色、标题、Badge 和业务模型可以原地变化。默认 UUID 仅是兼容兜底，不适合需要局部刷新的列表。

### 选中状态示例

```swift
model.isSelected = true
collectionView.reloadItemContent(at: [indexPath])
```

如果状态会改变 Cell 高度：

```swift
model.isSelected = true
collectionView.reloadSectionContent(at: [indexPath.section], invalidateLayout: true)
```

普通内容刷新不需要重新创建整个 `PTSection` / `PTRows` 数组，也不需要调用 `dataList()` 作为刷新手段。旧的 `showCollectionDetail`、`reloadSections` 和 `reloadRows` 仍然保留，用于兼容结构型调用。

### 布局变化不是内容刷新

布局类型、列数、item 高度、间距、Header/Footer pin、索引和 Decoration 会影响几何结果，
应进入布局事务；标题、选中态、图片和 Badge 不改变几何时只做内容刷新：

| 变化 | 推荐入口 | 是否改变 Diffable 身份 |
| --- | --- | --- |
| 标题、图片、选中态、Badge | `reloadItemContent(at:)` | 否 |
| Row/Section 数量或顺序 | `insertRows`、`deleteRows`、`insertSection`、`deleteSections` | 是业务结构变化 |
| Normal / Gird / WaterFall / Horizontal 等类型 | `switchLayout(to:)` | 否 |
| rowCount、itemHeight、spacing、pin/index/Decoration | `updateLayoutConfiguration` | 否 |

切换入口、四种滚动策略和 `.Gird` 的兼容说明见
[PTCollectionView 运行时 Layout 切换指南](PTCOLLECTIONVIEW_LAYOUT_SWITCH_GUIDE.md)。

### 内容刷新规则

`PTCollectionView` 内部的 Diffable 数据源只保存 `PTSectionIdentifier` 和 `PTRowIdentifier`。最新的可变
`PTSection` / `PTRows` 由内部 ModelStore 保存，因此只改变标题、选中态、图片或 Badge 时不会重新生成身份。
内容刷新会合并连续请求，先尝试对可见的 `PTBaseNormalCell`、`PTFusionCell` 或 `PTCellBindable` 做原地配置，
没有快速路径时才调用 `reconfigureItems`。需要替换 Cell 实例时才使用 `reloadItemCell` 或 `reloadSectionCells`。

Provider 需要最新 Row 时，优先使用：

```swift
collectionView.cellInCollectionV2 = { collectionView, context in
    collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCell", for: context.indexPath)
}

collectionView.configureCell = { _, cell, context in
    (cell as? MessageCell)?.render(context.row)
}
```

旧的 `cellInCollection` 仍会收到最新的 Section（其中的 Row 已由 ModelStore 同步），不要求业务立即迁移。

### Refresh Lab 数据源模式

Example Catalog 的 **Diffable Refresh Lab** 现在包含 Ref、Value、External、Store 四种数据来源模式，可分别验证引用模型、
Sendable 值快照、外部状态和 ModelStore 更新；刷新操作覆盖 Replace、Sections、Rows、Reconfigure、Item、Section Content、Replace Cell，
并提供 YD Sequence 和 Stress。页面会显示 Provider、Configure、Snapshot Apply、Pending 和最近一次操作耗时。

## Español

`PTCollectionView` separa las actualizaciones estructurales, de contenido y de geometría. `PTCollectionUpdateCoordinator` las serializa en `MainActor` y obtiene el snapshot cuando la operación comienza; las llamadas rápidas no se descartan ni sobrescriben un snapshot antiguo.

Use identidades estables en `PTSection(identifier:)` y `PTRows(diffId:)`. Para un cambio de estado visual, actualice el modelo y llame a `reloadItemContent(at:)` o `reloadSectionContent(at:)`. Use `invalidateLayout` solo cuando cambie la geometría real.

Para reemplazar modelos use `updateRow(_:)` o `updateRows(_:)`; use `reloadItemCell(at:)` o `reloadSectionCells(at:)` solo cuando cambie la clase o la ruta de reutilización de la celda. El laboratorio incluye una secuencia de selección de cuatro pasos y métricas de Provider/Configure.

## English

`PTCollectionView` separates structural, content, and layout updates. `PTCollectionUpdateCoordinator` serializes operations on `MainActor` and reads the snapshot at execution time, so rapid updates are not dropped or applied over stale snapshots.

Use stable identifiers with `PTSection(identifier:)` and `PTRows(diffId:)`. For a visual state change, mutate the model and call `reloadItemContent(at:)` or `reloadSectionContent(at:)`. Set `invalidateLayout` only when the cell or section geometry actually changes.

For replacing model objects use `updateRow(_:)` or `updateRows(_:)`; use `reloadItemCell(at:)` or `reloadSectionCells(at:)` only when the cell class or reuse path changes. The lab also includes the four-step YD selection sequence and live Provider/Configure metrics.

## 调试与验证 / Debugging / Depuración

Debug 构建会输出 `[PTCollection]` 操作编号、入队/执行/完成状态、时间、快照数量、待处理数量以及刷新范围。Release 构建不输出这类诊断。/ Debug builds log operation ID, enqueue/execute/finish timestamps, snapshot counts, pending count, and refresh ranges; Release builds omit these diagnostics. / Las compilaciones Debug registran el ID, los tiempos, los conteos y los rangos; Release no muestra estos diagnósticos.

固定复现页面为 Example Catalog 中的 **Diffable Refresh Lab**，覆盖整体替换、Section、Row、Reconfigure、单 Item、Section 内容刷新和快速 Stress 更新。/ The Example Catalog includes **Diffable Refresh Lab** for replacement, section, row, reconfigure, item, section-content, and rapid stress paths. / El catálogo Example incluye **Diffable Refresh Lab** para todos esos recorridos.

布局回归使用 **Collection Layout Switch Lab**，覆盖七种布局、配置切换、位置/选中恢复、Header/Footer、Decoration、Index、Skeleton 和连续压力操作。/ Layout regression uses **Collection Layout Switch Lab** for all seven layouts, configuration changes, anchor/selection restoration, supplementary views, decorations, index, skeleton, and queued stress. / La regresión de layout usa **Collection Layout Switch Lab** para las siete variantes y las operaciones de estrés.
