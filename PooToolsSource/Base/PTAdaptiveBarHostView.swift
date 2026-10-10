//
//  PTAdaptiveBarHostView.swift
//  PooTools
//
//  English: Provide a non-intercepting host for adaptive geometry and diagnostics.
//  Español: Proporciona un host que no intercepta toques para geometría y diagnóstico adaptativos.
//  中文：提供不拦截触摸的自适应几何与诊断宿主。
//

import UIKit

@MainActor
open class PTAdaptiveBarHostView: UIView {
    public let railView = PTVerticalBarRailView()
    public let debugOverlay = PTAdaptiveBarDebugOverlay()
    public private(set) var geometry: PTAdaptiveBarGeometry?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        addSubview(railView)
        addSubview(debugOverlay)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        addSubview(railView)
        addSubview(debugOverlay)
    }

    public func apply(geometry: PTAdaptiveBarGeometry, showDebugOverlay: Bool = false) {
        self.geometry = geometry
        railView.frame = geometry.customRailRect
        debugOverlay.frame = bounds
        debugOverlay.geometry = geometry
        debugOverlay.isHidden = !showDebugOverlay
    }
}
