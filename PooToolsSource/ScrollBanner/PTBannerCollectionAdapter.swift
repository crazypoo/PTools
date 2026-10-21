//
//  PTBannerCollectionAdapter.swift
//  PooTools
//
// English: Convert banner values into the canonical PTCollectionView contract.
// Español: Convierte los valores del banner al contrato canónico de PTCollectionView.
// 中文：将 Banner 数据转换为 PTCollectionView 的统一契约。
//

import UIKit
#if SWIFT_PACKAGE
import ptools
#endif

@MainActor
final class PTBannerCollectionAdapter {
    // English: Keep the adapter value-based so it cannot retain the banner or its cells.
    // Español: Mantiene el adaptador basado en valores para no retener el banner ni sus celdas.
    // 中文：适配器只处理值，不持有 Banner 或 Cell，避免生命周期循环。
    func makeScrollConfiguration(configuration: PTBannerConfiguration,
                                 itemCount: Int,
                                 defaultInterval: TimeInterval) -> PTCollectionScrollConfiguration {
        let horizontal = (configuration.scrollDirection ?? .horizontal) == .horizontal
        let style: PTCollectionScrollStyle
        if configuration.infiniteLoop && itemCount > 1 {
            style = horizontal ? .horizontalInfinite : .verticalInfinite
        } else {
            style = horizontal ? .horizontalPaging : .verticalPaging
        }

        return PTCollectionScrollConfiguration(
            style: style,
            paging: PTCollectionPagingConfiguration(
                snapMode: .viewport,
                itemAlignment: .leading,
                initialPage: 0,
                allowsSkippingPages: true,
                preservesVisibleRowOnUpdates: true
            ),
            infinite: PTCollectionInfiniteConfiguration(maxProjectedItems: 600),
            autoScroll: PTCollectionAutoScrollConfiguration(
                isEnabled: configuration.autoScroll && itemCount > 1,
                interval: configuration.autoScrollInterval ?? defaultInterval,
                pausesWhileInteracting: true,
                pausesWhenNotVisible: true,
                respectsReduceMotion: true
            )
        )
    }

    func makeSection(models: [PTBannerModel]) -> PTSection {
        let rows = models.map { model in
            PTRows(ID: PTBannerCell.ID,
                   diffId: model.identifier,
                   dataModel: model)
        }
        return PTSection(identifier: "PTBanner.banner", rows: rows)
    }
}
