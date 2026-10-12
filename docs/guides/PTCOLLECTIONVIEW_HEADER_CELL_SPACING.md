# PTCollectionView Header / Cell 间距指南

## 适用范围

本指南适用于 iOS 17+ / Swift 6+ 的 `PTCollectionView`。5.63.4 起，Header 的高度只由
`NSCollectionLayoutBoundarySupplementaryItem` 承担，不会再次被隐式加入 Section 顶部内边距。

## 推荐配置

```swift
let config = PTCollectionViewConfig()
config.viewType = .Gird
config.sectionEdges = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
config.contentTopSpace = 0
config.contentBottomSpace = 0
config.cellLeadingSpace = 8
config.cellTrailingSpace = 8

let list = PTCollectionView(viewConfig: config)
```

- `sectionEdges` 和 `PTSectionLayoutConfiguration.contentInsets` 是 Section 外侧留白。
- `contentTopSpace` / `contentBottomSpace` 是布局内容留白，每种布局只消费一次。
- `cellLeadingSpace` / `cellTrailingSpace` 是 Cell 或 Item 间距，不会改变 Header 到首个 Cell 的距离。
- `headerHeight` / `footerHeight` 只决定 Supplementary 自身尺寸，不能当作 Section padding。
- `headerSpacing` / `footerSpacing` 是显式的 Header/内容和 Footer/内容间距。

逐 Section 配置时，显式 `contentInsets` 优先于全局 `sectionEdges`：

```swift
section.layoutConfiguration = PTSectionLayoutConfiguration(
    contentInsets: NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 8, trailing: 0),
    headerSpacing: 8,
    footerSpacing: 8
)
```

## 自定义布局和嵌套列表

旧的 `customerLayout` 保持兼容；需要根据实际容器宽度计算时使用新的
`customerLayoutWithEnvironment`，不要使用 `UIScreen.main.bounds` 或整机屏幕宽度：

```swift
list.customerLayoutWithEnvironment = { _, section, environment in
    let width = max(1, environment.container.contentSize.width)
    let itemSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1),
        heightDimension: .estimated(56)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(
        widthDimension: .absolute(width),
        heightDimension: .estimated(56)
    )
    return NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
}
```

嵌套 Grid 应显式传入 `groupWidth`：

```swift
let group = UICollectionView.girdCollectionLayout(
    data: section.rows,
    groupWidth: environment.container.contentSize.width,
    itemHeight: 44,
    cellRowCount: 2
)
```

`girdCollectionLayout(sectionContentInsets:)` 为源码兼容仍保留，但它只返回 Group，不能设置
`NSCollectionLayoutSection.contentInsets`。请改用 `PTSectionLayoutConfiguration.contentInsets`
或 `PTCollectionViewConfig.sectionEdges`。

如果通过 `customerReuseViews` 返回的自定义 Supplementary 已经设置了非零 `offset`，该 offset
视为调用方自行管理的间距，底层不会再叠加同一方向的 `headerSpacing` 或 `footerSpacing`。

## 动态修改布局

直接修改 Header/Footer 高度或布局配置后，调用 `invalidateSectionLayout`；它会清理 Section
布局缓存并触发 UIKit 重新计算：

```swift
section.headerHeight = 64
section.layoutConfiguration?.headerSpacing = 8
list.invalidateSectionLayout(at: [0])
```

如果修改了 Cell 类型或复用路径，使用现有的 `reloadSections` / `reloadSectionCells`，不要只
清理业务数据。布局切换仍可使用 `switchLayout`，不会把旧 Header 间距带回新布局。

## 间距测量

不要只观察 Header 内部 Label 的视觉位置。应比较 UIKit 的真实布局属性：

```swift
let collectionView = list.contentCollectionView
collectionView.layoutIfNeeded()

let indexPath = IndexPath(item: 0, section: 0)
if let header = collectionView.layoutAttributesForSupplementaryElement(
    ofKind: UICollectionView.elementKindSectionHeader,
    at: indexPath
), let cell = collectionView.layoutAttributesForItem(at: indexPath) {
    let gap = cell.frame.minY - header.frame.maxY
    print("header=\(header.frame) cell=\(cell.frame) gap=\(gap)")
}
```

如果 `gap` 已经是 0，但画面仍有空白，应检查 Header 内部约束、透明背景、父 Cell 高度、
`contentInset` 和 `adjustedContentInset`，不要用负 inset 抵消底层布局错误。

## 验证范围

间距回归覆盖 Normal、Grid、Custom、estimated-height、Decoration、Footer、动态 Header 高度、
嵌套列表和运行时布局切换。真实业务项目仍需在直屏、横屏、分屏、iPhone Duo 和不同 Safe Area
下验证视觉结果；静态检查和 Simulator 构建不能替代宿主项目的最终验收。

