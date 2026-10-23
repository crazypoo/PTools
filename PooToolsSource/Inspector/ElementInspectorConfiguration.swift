//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
#if SWIFT_PACKAGE
import ptools
#endif

@MainActor
final class ElementInspectorConfiguration {
    var isPresentingFromBottomSheet: Bool {
        return isPhoneIdiom
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
        panelPreferredCompressedSize(in: nil)
    }

    func panelPreferredCompressedSize(in bounds: CGRect?) -> CGSize {
        let hostWidth = bounds?.width ?? PTSceneContext.activeWindow()?.bounds.width ?? 0
        let resolvedWidth = hostWidth > 0 ? hostWidth : 414
        return CGSize(width: min(resolvedWidth, 414), height: .zero)
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
