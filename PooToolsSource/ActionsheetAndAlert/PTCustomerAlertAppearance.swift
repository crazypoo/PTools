//
//  PTCustomerAlertAppearance.swift
//  PooTools
//
// English: Keep customer-alert layout, accessibility, and surface values in one value configuration.
// Español: Mantiene en una configuración de valores el diseño, la accesibilidad y la superficie de la alerta.
// 中文：将自定义 Alert 的布局、辅助功能和背景表面配置集中到一个值类型中。
//

import UIKit

/// English: Selects the glass surface used by PTCustomerAlertController.
/// Español: Selecciona la superficie de vidrio usada por PTCustomerAlertController.
/// 中文：选择 PTCustomerAlertController 使用的玻璃背景样式。
public enum PTCustomerAlertGlassStyle: Sendable {
    case automatic
    case regular
    case clear
}

/// English: Controls the alert corner radius while preserving the legacy initializer value.
/// Español: Controla el radio de las esquinas y conserva el valor del inicializador heredado.
/// 中文：控制 Alert 圆角，同时保留旧初始化参数的兼容行为。
public enum PTCustomerAlertCornerStyle: Sendable {
    case system
    case fixed(CGFloat)
}

/// English: Describes the semantic role of an alert action.
/// Español: Describe el papel semántico de una acción de alerta.
/// 中文：描述 Alert 操作按钮的语义角色。
public enum PTCustomerAlertActionStyle: Sendable {
    case `default`
    case cancel
    case destructive
}

/// English: Appearance is intentionally value-based so callers can configure an alert before presentation.
/// Español: La apariencia usa valores inmutables para configurarla antes de presentar la alerta.
/// 中文：外观使用值类型，调用方可以在展示前安全配置 Alert。
public struct PTCustomerAlertAppearance: Sendable {
    public var glassEnabled: Bool
    public var glassStyle: PTCustomerAlertGlassStyle
    public var respectsReduceTransparency: Bool
    public var cornerStyle: PTCustomerAlertCornerStyle
    public var contentInsets: UIEdgeInsets
    public var titleMessageSpacing: CGFloat
    public var minimumSingleTextContentHeight: CGFloat
    public var minimumDualTextContentHeight: CGFloat
    public var actionBaseHeight: CGFloat
    public var separatorAlpha: CGFloat
    public var dimmingAlpha: CGFloat
    public var maximumWidth: CGFloat
    public var maximumHeightRatio: CGFloat

    public init(
        glassEnabled: Bool = true,
        glassStyle: PTCustomerAlertGlassStyle = .automatic,
        respectsReduceTransparency: Bool = true,
        cornerStyle: PTCustomerAlertCornerStyle = .system,
        contentInsets: UIEdgeInsets = .init(top: 20, left: 20, bottom: 18, right: 20),
        titleMessageSpacing: CGFloat = 6,
        minimumSingleTextContentHeight: CGFloat = 62,
        minimumDualTextContentHeight: CGFloat = 88,
        actionBaseHeight: CGFloat = 50,
        separatorAlpha: CGFloat = 0.35,
        dimmingAlpha: CGFloat = 0.28,
        maximumWidth: CGFloat = 340,
        maximumHeightRatio: CGFloat = 0.82
    ) {
        self.glassEnabled = glassEnabled
        self.glassStyle = glassStyle
        self.respectsReduceTransparency = respectsReduceTransparency
        self.cornerStyle = cornerStyle
        self.contentInsets = contentInsets
        self.titleMessageSpacing = titleMessageSpacing
        self.minimumSingleTextContentHeight = minimumSingleTextContentHeight
        self.minimumDualTextContentHeight = minimumDualTextContentHeight
        self.actionBaseHeight = actionBaseHeight
        self.separatorAlpha = separatorAlpha
        self.dimmingAlpha = dimmingAlpha
        self.maximumWidth = maximumWidth
        self.maximumHeightRatio = maximumHeightRatio
    }

    public static let `default` = Self()
}
