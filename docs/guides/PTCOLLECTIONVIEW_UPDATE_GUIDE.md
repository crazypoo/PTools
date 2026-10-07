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
| Section 几何变化 | `invalidateSectionLayout(at:)` |
| 单个 Item 的高度或瀑布流几何变化 | `invalidateItemLayout(at:)` |

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

## Español

`PTCollectionView` separa las actualizaciones estructurales, de contenido y de geometría. `PTCollectionUpdateCoordinator` las serializa en `MainActor` y obtiene el snapshot cuando la operación comienza; las llamadas rápidas no se descartan ni sobrescriben un snapshot antiguo.

Use identidades estables en `PTSection(identifier:)` y `PTRows(diffId:)`. Para un cambio de estado visual, actualice el modelo y llame a `reloadItemContent(at:)` o `reloadSectionContent(at:)`. Use `invalidateLayout` solo cuando cambie la geometría real.

## English

`PTCollectionView` separates structural, content, and layout updates. `PTCollectionUpdateCoordinator` serializes operations on `MainActor` and reads the snapshot at execution time, so rapid updates are not dropped or applied over stale snapshots.

Use stable identifiers with `PTSection(identifier:)` and `PTRows(diffId:)`. For a visual state change, mutate the model and call `reloadItemContent(at:)` or `reloadSectionContent(at:)`. Set `invalidateLayout` only when the cell or section geometry actually changes.

## 调试与验证 / Debugging / Depuración

Debug 构建会输出 `[PTCollection]` 操作编号、入队/执行/完成状态、时间、快照数量、待处理数量以及刷新范围。Release 构建不输出这类诊断。/ Debug builds log operation ID, enqueue/execute/finish timestamps, snapshot counts, pending count, and refresh ranges; Release builds omit these diagnostics. / Las compilaciones Debug registran el ID, los tiempos, los conteos y los rangos; Release no muestra estos diagnósticos.

固定复现页面为 Example Catalog 中的 **Diffable Refresh Lab**，覆盖整体替换、Section、Row、Reconfigure、单 Item、Section 内容刷新和快速 Stress 更新。/ The Example Catalog includes **Diffable Refresh Lab** for replacement, section, row, reconfigure, item, section-content, and rapid stress paths. / El catálogo Example incluye **Diffable Refresh Lab** para todos esos recorridos.
