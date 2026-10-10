//
//  PTAdaptiveBarPresentationPolicy.swift
//  PooTools
//
//  English: Stable policy and value types for adaptive navigation and tab bars.
//  Español: Políticas y tipos de valor estables para barras adaptativas de navegación y pestañas.
//  中文：为自适应导航栏和 TabBar 提供稳定的策略与值类型。
//

import UIKit

public enum PTAdaptiveBarPresentationPolicy: String, Sendable, Equatable {
    case automatic
    case preferSystemAdaptive
    case customAdaptive
    case preferClassicBarsForWideContent
    case legacyClassic
}

public enum PTAdaptiveBarAxis: String, Sendable, Equatable {
    case horizontalClassic
    case verticalEdge
}

public enum PTAdaptiveBarEdge: String, Sendable, Equatable {
    case unspecified
    case leading
    case trailing
}

public enum PTAdaptiveBarRenderer: String, Sendable, Equatable {
    case legacyClassic
    case systemAdaptive
    case customAdaptive
}

// English: This configuration is per controller so separate scenes never share live geometry state.
// Español: Esta configuración pertenece al controlador para que las escenas no compartan geometría viva.
// 中文：配置属于控制器实例，避免不同 Scene 共享实时几何状态。
public struct PTAdaptiveBarConfiguration: Sendable, Equatable {
    public var presentationPolicy: PTAdaptiveBarPresentationPolicy
    public var minimumTouchTarget: CGFloat
    public var favorsTabVisibility: Bool
    public var enablesCustomEffects: Bool

    public init(presentationPolicy: PTAdaptiveBarPresentationPolicy = .automatic,
                minimumTouchTarget: CGFloat = 44,
                favorsTabVisibility: Bool = true,
                enablesCustomEffects: Bool = true) {
        self.presentationPolicy = presentationPolicy
        self.minimumTouchTarget = minimumTouchTarget
        self.favorsTabVisibility = favorsTabVisibility
        self.enablesCustomEffects = enablesCustomEffects
    }
}
