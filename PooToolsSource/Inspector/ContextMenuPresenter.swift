//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class ContextMenuPresenter: NSObject, UIContextMenuInteractionDelegate {
    private let configurationProvider: (UIContextMenuInteraction) -> UIContextMenuConfiguration?
    private var store: [ObjectIdentifier: UIContextMenuInteraction] = [:]

    init(configurationProvider: @escaping (UIContextMenuInteraction) -> UIContextMenuConfiguration?) {
        self.configurationProvider = configurationProvider
    }

    func addInteraction(to view: UIView) {
        let key = view.objectIdentifier

        guard
            view.canHostContextMenuInteraction,
            view.allSuperviews.filter({ $0 is InternalViewProtocol }).isEmpty,
            store[key] == nil
        else {
            return
        }

        let interaction = UIContextMenuInteraction(delegate: self)
        view.addInteraction(interaction)
        store[key] = interaction
    }

    func removeInteraction(from view: UIView) {
        let key = view.objectIdentifier
        guard let interaction = store[key] else { return }
        view.removeInteraction(interaction)
        store[key] = nil
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
    {
        configurationProvider(interaction)
    }
}
