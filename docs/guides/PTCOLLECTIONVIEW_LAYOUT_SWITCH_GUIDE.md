# PTCollectionView 运行时 Layout 切换指南

> iOS 17+ / Swift 6 / UIKit

## 中文

### 适用范围

`PTCollectionView` 的布局切换只替换内部 `UICollectionViewCompositionalLayout`，不会重建
`UICollectionView`、Diffable snapshot 或业务数据。布局事务通过现有
`PTCollectionUpdateCoordinator` 串行执行；因此可以安全地把布局切换和内容、结构更新连续排队。

### 新旧 API

初始化时仍然可以使用旧方式：

```swift
let config = PTCollectionViewConfig()
config.viewType = .Normal
let list = PTCollectionView(viewConfig: config)
```

运行中的列表使用新的受控入口：

```swift
list.switchLayout(to: .Gird,
                  animated: true,
                  scrollPolicy: .firstVisibleItem)

list.updateLayoutConfiguration(animated: true) { config in
    config.viewType = .Gird
    config.rowCount = 2
    config.itemHeight = 72
    config.cellLeadingSpace = 8
    config.cellTrailingSpace = 8
}
```

`switchLayout` 和 `updateLayoutConfiguration` 的 completion 参数会在 MainActor 回调，并以
`Bool` 表示事务是否完成。旧的 `viewConfig` 替换仍兼容，但应优先使用新 API；直接修改同一个
`viewConfig` 对象的属性不会触发隐式布局事务，请改用 `updateLayoutConfiguration`。

### 七种布局

公开枚举当前保留历史拼写 `.Gird`，不是 `.Grid`：

```swift
enum PTCollectionViewType {
    case Normal
    case Gird                 // 现有公开拼写，请勿改成不存在的 .Grid
    case WaterFall
    case Custom
    case Horizontal
    case HorizontalLayoutSystem
    case Tag
}
```

`.Custom` 必须先提供 `customerLayout`；缺少 callback 时切换会安全拒绝并返回 `false`，不会把
现有可用布局替换成空布局。`.Tag` 需要使用 `PTTagLayoutModel` 数据模型，否则会退化到安全的
单格布局，并记录诊断信息。

### 位置和选中状态

`PTCollectionLayoutScrollPolicy` 提供四种策略：

| 策略 | 行为 |
| --- | --- |
| `.firstVisibleItem` | 按稳定 `diffId` 恢复第一可见 Row，并保留相对偏移；锚点被删除时选择最近有效 Row |
| `.contentOffset` | 尽量保留当前 `contentOffset`，随后按内容尺寸和 inset 约束 |
| `.top` | 回到 adjusted content inset 顶部 |
| `.none` | 不主动恢复位置 |

切换前的 selected Row 会按稳定 `diffId` 重新选中，不依赖旧 IndexPath。布局切换不会重新请求
业务数据，也不会改变 Diffable 的 Section/Row 身份。

### 自定义 Header、Footer、Decoration

Header、Footer、Decoration 仍由现有 `PTCollectionViewConfig` 和注册入口管理。布局配置变化
会重新注册/同步 index、refresh、bounce、prefetch、pin header/footer 和 skeleton 行为，但
不会改变业务 Cell provider。自定义 decoration 需要在 `decorationModel` 中提供有效 class 和 ID，
并通过已有 `decorationInCollectionView` 返回 decoration items。

### 常见错误

- 把内容变化当成布局变化：标题、选中态、图片只调用 `reloadItemContent`；几何变化才调用
  `updateLayoutConfiguration`。
- 在排队操作外直接修改共享 `viewConfig`，导致后一个配置污染前一个事务。
- 使用运行时随机 `diffId`，导致锚点、选中状态和 Diffable 更新无法恢复。
- `.Custom` 没有设置 `customerLayout`，应检查 completion 的 `false`。
- 把 `.Gird` 写成 `.Grid`；`.Gird` 是当前兼容 API 的正式公开 case。

### Example Catalog 验证

进入 **Collection Layout Switch Lab**（稳定 ID：`ui.collection-layout-switch-lab`），可验证
七种布局、1/100/1,000 条数据、Row 插入/删除、连续布局切换、Header/Footer、Decoration、pin、
Index、Skeleton、动画、Reduce Motion 和四种滚动策略。页面会显示稳定 Row-ID、offset、
`snapshotApplyCount`、`pendingUpdateCount`、当前操作类型和完成状态。

## Español

`PTCollectionView` reemplaza únicamente la instancia de `UICollectionViewCompositionalLayout`; no
recrea la colección ni las identidades Diffable. Use `switchLayout` para cambiar solo el tipo y
`updateLayoutConfiguration` para cambiar tipo y geometría dentro de una transacción serializada.

La API pública conserva el nombre histórico `.Gird`; no existe `.Grid`. `.Custom` requiere
`customerLayout`, `.Tag` requiere `PTTagLayoutModel` y las cuatro políticas de scroll restauran la
posición de forma explícita. La selección se restaura por `diffId` estable, no por un IndexPath viejo.

Use **Collection Layout Switch Lab** para comprobar las siete variantes, cambios de tamaño, datos
grandes, refresh, decoration, index, skeleton y operaciones rápidas en el catálogo de Example.

## English

`PTCollectionView` replaces only the internal `UICollectionViewCompositionalLayout`; it does not
recreate the collection view, the Diffable snapshot, or business models. Use `switchLayout` for a
type change and `updateLayoutConfiguration` for a serialized type and geometry transaction.

The public API intentionally keeps the historical `.Gird` spelling; `.Grid` does not exist. `.Custom`
requires `customerLayout`, `.Tag` requires `PTTagLayoutModel`, and selection is restored by stable
`diffId` rather than stale index paths. The scroll policy controls first-visible-item, content offset,
top, or no explicit restoration.

Use **Collection Layout Switch Lab** in the Example Catalog to exercise all seven layouts, large data
sets, header/footer, decorations, pinning, index, skeleton, Reduce Motion, and queued stress updates.

