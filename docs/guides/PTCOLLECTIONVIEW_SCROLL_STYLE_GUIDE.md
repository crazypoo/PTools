# PTCollectionView 滚动样式指南

## 适用范围

`PTCollectionScrollStyle` 只描述主 `UICollectionView` 的滚动行为，`PTCollectionViewType` 继续负责排版。当前实现面向 iOS 17+ / Swift 6+，并复用 Core 的 Diffable、ModelStore、刷新、骨架和布局事务。

```swift
let config = PTCollectionViewConfig()
config.scrollConfiguration = PTCollectionScrollConfiguration(
    style: .horizontalPaging,
    paging: PTCollectionPagingConfiguration(
        snapMode: .viewport,
        allowsSkippingPages: false
    )
)

let list = PTCollectionView(viewConfig: config)
list.onPageChanged = { context in
    print("page=\(context.page)/\(context.pageCount)")
}
```

## 样式和限制

- `.normal` 保留原有多 Section、正交滚动、刷新和拖放行为。
- `.horizontalPaging` / `.verticalPaging` 使用主轴分页，并通过 `onPageChanged` 提供逻辑页码。
- `.horizontalInfinite` / `.verticalInfinite` 只接受单 Section、viewport 吸附和稳定的 V2 Cell Provider；拖放、刷新、智能触底和自定义 Header/Footer 会被拒绝。
- 0 或 1 条数据的无限配置会安全降级为有限分页，不会创建无意义的循环投影。
- 无限模式下 Diffable 的物理 ID 只属于展示层；业务仍使用真实 `PTRows.diffId` 和 `onLogicalItemSelected`。

## 交互和自动滚动

`PTCollectionAutoScrollConfiguration` 由 MainActor 协调器管理单一可取消任务。用户开始拖动时会暂停自动滚动；无减速的拖动在 `didEndDragging` 恢复，有减速的拖动在 `didEndDecelerating` 恢复。进入后台、离开窗口、骨架显示和 Reduce Motion 也会暂停。

分页列表如果不需要滚动条，可以通过配置关闭：

```swift
config.showsHorizontalScrollIndicator = false
config.showsVerticalScrollIndicator = false
list.setScrollIndicatorsHidden(true)
```

## 平台边界

这是 UIKit 列表实现，直接 UI 支持为 iOS 17+。滚动配置和身份模型属于 Core 值类型，可在 watchOS、visionOS 和 macOS 的对应宿主中复用；当前仓库没有把 `UICollectionView` 适配器宣称为这些平台的直接 UI 实现。

## Español / English

`PTCollectionScrollStyle` defines main-axis behavior while `PTCollectionViewType` keeps layout geometry. The UIKit implementation targets iOS 17+ and Swift 6. The value contracts can be reused by watchOS, visionOS, and macOS adapters, but the current `UICollectionView` host remains iOS-only.

`PTCollectionScrollStyle` define el comportamiento del eje principal y `PTCollectionViewType` conserva la geometría. La implementación UIKit apunta a iOS 17+ y los contratos de valores pueden reutilizarse mediante adaptadores para watchOS, visionOS y macOS.
