//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class ElementInspectorConfiguration {
    var isPresentingFromBottomSheet: Bool {
        if #available(iOS 15.0, *) {
            return isPhoneIdiom
        }
        return false
    }

    var isPhoneIdiom: Bool {
        guard let userInterfaceIdiom = ViewHierarchy.shared.keyWindow?.traitCollection.userInterfaceIdiom else {
            // assume true
            return true
        }
        return userInterfaceIdiom == .phone
    }

    var defaultPanel: ElementInspectorPanel = .identity

    var childrenListMaximumInteractiveDepth = 4

    var animationDuration: TimeInterval = CATransaction.animationDuration()

    var panelPreferredCompressedSize: CGSize {
        CGSize(
            width: min(UIScreen.main.bounds.width, 414),
            height: .zero
        )
    }

    let panelSidePresentationAvailable: Bool = true

    var panelSidePresentationMinimumContainerSize: CGSize {
        CGSize(
            width: 768,
            height: 768
        )
    }

    var thumbnailBackgroundStyle: ThumbnailBackgroundStyle = .systemBackground
}
