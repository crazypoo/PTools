//
//  UIWindow+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

@MainActor
extension UIWindow {

    // MARK: - SnapshotKitProtocol 实现 (覆盖 UIView 的默认实现)

    internal func pt_windowSnapshot(configuration: SnapshotConfiguration) -> UIImage? {
        PTSnapshotRenderer.image(view: self,
                                 rect: bounds,
                                 configuration: configuration,
                                 usesHierarchy: true)
    }

    // MARK: - Compatibility entry points / Entradas de compatibilidad / 兼容入口

    public func windowTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        pt_windowSnapshot(configuration: configuration)
    }

    public func windowTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        pt_windowSnapshot(configuration: configuration)
    }

    public func windowAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            completion(self?.pt_windowSnapshot(configuration: configuration))
        }
    }
}
