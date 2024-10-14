//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

typealias Closure = () -> Void

public final class Inspector {
    // MARK: - Public Properties

    public var configuration: InspectorConfiguration = .default {
        didSet {
            restartIfNeeded()
        }
    }

    public var customization: InspectorCustomizationProviding? {
        didSet {
            restartIfNeeded()
        }
    }

    // MARK: - Private Properties

    enum State {
        case idle, started
    }

    private(set) var manager: Manager?

    var state: State { manager == nil ? .idle : .started }

    // MARK: - Internal Properties

    static let sharedInstance = Inspector()

    let appearance = InspectorAppearance()

    private(set) lazy var console = ConsoleLogger { [weak self] in
        self?.manager?.snapshot
    }

    private(set) var contextMenuPresenter: ContextMenuPresenter?

    private(set) var swiftUIHost: InspectorSwiftUIHost?

    func start(swiftUI swiftUIHost: InspectorSwiftUIHost) {
        self.swiftUIHost = swiftUIHost
        restart()
    }

    func start() {
        setup()
        manager?.start()
    }

    func stop() {
        manager = .none
        contextMenuPresenter = .none
    }

    private func restartIfNeeded() {
        if state == .started { restart() }
    }

    private func restart() {
        stop()
        start()
    }

    private func setup() {
        manager = Manager(
            .init(
                configuration: configuration,
                coordinatorFactory: ViewHierarchyCoordinatorFactory.self,
                customization: customization,
                viewHierarchy: ViewHierarchy.shared,
                swiftUIhost: swiftUIHost
            ),
            presentedBy: OperationQueue.main
        )

        contextMenuPresenter = ContextMenuPresenter { [weak self] interaction in
            guard
                let self = self,
                let sourceView = interaction.view,
                let viewHierarchy = self.manager?.snapshot.root.viewHierarchy,
                let element = viewHierarchy.first(where: { $0.underlyingView === interaction.view })
            else {
                return .none
            }
            return .contextMenuConfiguration(
                with: element,
                includeActions: true
            ) { [weak self] reference, action in
                guard let self = self else { return }
                self.manager?.perform(
                    action: action,
                    with: reference,
                    from: sourceView
                )
            }
        }
    }
}

// MARK: - Presentation

extension Inspector {
    func present(animated: Bool = true) {
        manager?.presentInspector(animated: animated)
    }
}

// MARK: - Element

extension Inspector {
    func isInspecting(_ view: UIView) -> Bool {
        view.allSubviews.contains { $0 is LayerViewProtocol }
    }

    func inspect(_ view: UIView, animated: Bool = true) {
        manager?.startElementInspectorCoordinator(
            for: view,
            panel: .default,
            from: view,
            animated: animated
        )
    }
}

// MARK: - View Hierarchy Layer

extension Inspector {
    func isInspecting(_ layer: Inspector.ViewHierarchyLayer) -> Bool {
        manager?.isShowingLayer(layer) ?? false
    }

    func inspect(_ layer: Inspector.ViewHierarchyLayer) {
        manager?.toggleLayer(layer)
    }

    func toggle(_ layer: Inspector.ViewHierarchyLayer) {
        manager?.toggleLayer(layer)
    }

    func toggleAllLayers() {
        manager?.toggleAllLayers()
    }

    func stopInspecting(_ layer: Inspector.ViewHierarchyLayer) {
        manager?.removeLayer(layer)
    }

    func removeAllLayers() {
        manager?.removeAllLayers()
    }
}

// MARK: - KeyCommands

extension Inspector {
    var keyCommands: [UIKeyCommand] {
        manager?.keyCommands ?? []
    }
}

// MARK: - Public API

public extension Inspector {
    static func start() {
        sharedInstance.start()
    }

    static func stop() {
        sharedInstance.stop()
    }

    static func present(animated: Bool = true) {
        sharedInstance.present(animated: animated)
    }

    static func isInspecting(_ view: UIView) -> Bool {
        sharedInstance.isInspecting(view)
    }

    static func inspect(_ view: UIView, animated: Bool = true) {
        sharedInstance.inspect(view, animated: animated)
    }

    static func isInspecting(_ layer: Inspector.ViewHierarchyLayer) -> Bool {
        sharedInstance.isInspecting(layer)
    }

    static func inspect(_ layer: Inspector.ViewHierarchyLayer) {
        sharedInstance.inspect(layer)
    }

    static func toggle(_ layer: Inspector.ViewHierarchyLayer) {
        sharedInstance.toggle(layer)
    }

    static func toggleAllLayers() {
        sharedInstance.toggleAllLayers()
    }

    static func stopInspecting(_ layer: Inspector.ViewHierarchyLayer) {
        sharedInstance.stopInspecting(layer)
    }

    static func removeAllLayers() {
        sharedInstance.removeAllLayers()
    }

    static var keyCommands: [UIKeyCommand]? {
        sharedInstance.keyCommands
    }

    static func setConfiguration(_ configuration: InspectorConfiguration?) {
        sharedInstance.configuration = configuration ?? .default
    }

    static func setCustomization(_ customization: InspectorCustomizationProviding?) {
        sharedInstance.customization = customization
    }
}
