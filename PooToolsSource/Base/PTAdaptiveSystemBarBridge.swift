//
//  PTAdaptiveSystemBarBridge.swift
//  PooTools
//
//  English: Apply only stable UIKit adaptive-bar preferences to system containers.
//  Español: Aplica únicamente preferencias estables de UIKit a los contenedores del sistema.
//  中文：只向系统容器应用稳定的 UIKit 自适应 Bar 偏好。
//

import UIKit

@MainActor
public enum PTAdaptiveSystemBarBridge {
    public static func apply(policy: PTAdaptiveBarPresentationPolicy,
                             to navigationController: UINavigationController) {
        guard #available(iOS 27.1, *) else { return }
        let compression: UIVerticalBarCompressionBehavior
        switch policy {
        case .legacyClassic, .preferClassicBarsForWideContent:
            compression = .automatic
        case .automatic, .preferSystemAdaptive, .customAdaptive:
            compression = .automatic
        }
        navigationController.topViewController?.navigationItem.verticalBarCompressionBehavior = compression
        navigationController.setNeedsUpdateOfVerticalBarConfiguration()
    }
}
