//
//  PTAdaptiveBarCoordinator.swift
//  PooTools
//
//  English: Own one adaptive geometry transaction for one view-controller host.
//  Español: Posee una única transacción geométrica adaptativa por host de controlador.
//  中文：为每个控制器宿主统一拥有一次自适应几何布局事务。
//

import UIKit

@MainActor
public final class PTAdaptiveBarCoordinator {
    public var configuration: PTAdaptiveBarConfiguration {
        didSet { invalidate() }
    }

    private weak var hostView: UIView?
    private var lastSignature: Signature?
    public private(set) var geometry: PTAdaptiveBarGeometry?
    public private(set) var generation: UInt = 0

    private struct Signature: Equatable {
        let context: PTAdaptiveBarLayoutContext
        let policy: PTAdaptiveBarPresentationPolicy
        let minimumTouchTarget: CGFloat
        let navigationActionCount: Int
        let tabItemIDs: [String]
        let selectedTabID: String?
        let accessoryHeight: CGFloat
    }

    public init(hostView: UIView? = nil,
                configuration: PTAdaptiveBarConfiguration = .init()) {
        self.hostView = hostView
        self.configuration = configuration
    }

    public func attach(to hostView: UIView) {
        self.hostView = hostView
        invalidate()
    }

    public func invalidate() {
        lastSignature = nil
    }

    @discardableResult
    public func update(navigationActionCount: Int,
                       tabItemIDs: [String],
                       selectedTabID: String?,
                       accessoryHeight: CGFloat = 0) -> PTAdaptiveBarGeometry? {
        guard let hostView else { return geometry }
        let context = PTAdaptiveBarLayoutContext.make(for: hostView)
        let signature = Signature(context: context,
                                  policy: configuration.presentationPolicy,
                                  minimumTouchTarget: configuration.minimumTouchTarget,
                                  navigationActionCount: navigationActionCount,
                                  tabItemIDs: tabItemIDs,
                                  selectedTabID: selectedTabID,
                                  accessoryHeight: accessoryHeight)
        guard signature != lastSignature else { return geometry }
        lastSignature = signature
        generation &+= 1
        geometry = PTAdaptiveBarLayoutResolver.resolve(context: context,
                                                        configuration: configuration,
                                                        navigationActionCount: navigationActionCount,
                                                        tabItemIDs: tabItemIDs,
                                                        selectedTabID: selectedTabID,
                                                        accessoryHeight: accessoryHeight)
        return geometry
    }
}
