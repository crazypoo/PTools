// English: Compatibility data source that converts the old model array into a native snapshot.
// Español: Fuente de datos de compatibilidad que convierte el array antiguo en un snapshot nativo.
// 中文：将旧模型数组转换为原生快照的兼容数据源。

import UIKit

@MainActor
@available(*, deprecated, message: "Use PTSegmentedView.apply(items:) instead.")
public class PTMainSegmentDataSource: NSObject {
    open var dataSourceData = [PTSegmentControlBaseModel]()
    open var change: PTSegmentControlModelType? = .ImageTitle(type: .Normal)
    open var titleNormalColor: UIColor = .black
    open var titleSelectedColor: UIColor = .black
    open var itemWidths: CGFloat = UIScreen.main.bounds.width / 4
    open var itemWidthIncrement: CGFloat = 20
    open var itemSpacing: CGFloat = 0
    public private(set) var items = [PTSegmentItem]()

    public override init() {
        super.init()
    }

    /// English: Builds native items with stable integer IDs for the legacy data source.
    /// Español: Construye elementos nativos con IDs enteros estables para la fuente antigua.
    /// 中文：为旧数据源构建带稳定整数 ID 的原生分段项。
    public func makeItems() -> [PTSegmentItem] {
        dataSourceData.enumerated().map { index, model in
            let content: PTSegmentContent
            switch change ?? .ImageTitle(type: .Normal) {
            case .OnlyImage:
                if let url = URL(string: model.imageURL), !model.imageURL.isEmpty {
                    content = .imageSource(.url(url))
                } else {
                    content = .title(model.categoryName)
                }
            case .ImageTitle:
                if let url = URL(string: model.imageURL), !model.imageURL.isEmpty {
                    content = .titleImageSource(title: model.categoryName, source: .url(url), placement: .leading)
                } else {
                    content = .title(model.categoryName)
                }
            case .OnlyTitle:
                content = .title(model.categoryName)
            }
            return PTSegmentItem(id: index, content: content)
        }
    }

    /// English: Applies the compatibility models to a native segmented view.
    /// Español: Aplica los modelos de compatibilidad a una vista segmentada nativa.
    /// 中文：将兼容模型应用到原生分段 View。
    public func apply(to segmentedView: PTSegmentedView,
                      selectedIndex: Int = 0,
                      animated: Bool = true) {
        items = makeItems()
        segmentedView.style.normalColor = titleNormalColor
        segmentedView.style.selectedColor = titleSelectedColor
        segmentedView.style.itemWidths = itemWidths > 0 ? Array(repeating: itemWidths, count: items.count) : nil
        segmentedView.apply(items: items, animatingDifferences: animated)
        segmentedView.select(index: selectedIndex, animated: false, origin: .restoration)
    }

    /// English: Refreshes the native item cache; old callers can then call apply(to:).
    /// Español: Actualiza la caché de elementos nativos; los llamadores antiguos pueden llamar a apply(to:).
    /// 中文：刷新原生分段项缓存；旧调用方随后可调用 apply(to:)。
    public func reloadData(selectedIndex: Int = 0) {
        items = makeItems()
        _ = selectedIndex
    }

    public func preferredItemWidth(at index: Int) -> CGFloat {
        guard items.indices.contains(index) else { return itemWidths }
        return itemWidths > 0 ? itemWidths : PTMainSegmentCell.measuredWidth(item: items[index], style: PTSegmentStyle())
    }
}
