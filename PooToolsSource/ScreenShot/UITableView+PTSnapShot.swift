//
//  UITableView+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

@MainActor
extension UITableView {

    // English: Use the scroll-view renderer so table cells and headers share one capture path.
    // Español: Usa el renderizador del scroll view para que las celdas y cabeceras compartan una ruta de captura.
    // 中文：复用滚动视图渲染器，让表格 Cell 和表头统一走同一条截图路径。
    internal func pt_tableVisibleSnapshot(configuration: SnapshotConfiguration) -> UIImage? {
        pt_scrollVisibleSnapshot(configuration: configuration)
    }

    internal func pt_tableFullSnapshot(configuration: SnapshotConfiguration) -> UIImage? {
        pt_scrollFullSnapshot(configuration: configuration)
    }

    internal func pt_tableAsyncSnapshot(configuration: SnapshotConfiguration) async -> UIImage? {
        await pt_scrollAsyncSnapshot(configuration: configuration)
    }

    // MARK: - Compatibility entry points / Entradas de compatibilidad / 兼容入口

    public func tableTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        pt_tableVisibleSnapshot(configuration: configuration)
    }

    public func tableTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        pt_tableFullSnapshot(configuration: configuration)
    }

    public func tableAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration,
                                                     completion: @escaping @Sendable (UIImage?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else {
                completion(nil)
                return
            }
            let image = await self.pt_tableAsyncSnapshot(configuration: configuration)
            guard !Task.isCancelled else { return }
            completion(image)
        }
    }
}
