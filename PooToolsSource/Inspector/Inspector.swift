//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public typealias Closure = @MainActor @Sendable () -> Void

// 1. 核心类显式标记为 @MainActor，保证内部所有 UIKit 操作的数据安全性
@MainActor
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

    // 静态单例自动继承 @MainActor 隔离
    static let sharedInstance = Inspector()

    // 保证在主线程上下文中初始化带有主线程属性的结构体
    let appearance = InspectorAppearance()

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
                viewHierarchy: ViewHierarchy.shared, // 假设 ViewHierarchy.shared 也是主线程安全或 Sendable 的
                swiftUIhost: swiftUIHost
            ),
            presentedBy: OperationQueue.main
        )

        // 闭包继承 @MainActor 上下文，安全捕获 weak self 和 UIKit 元素
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
// 2. 对外暴露的便捷静态 API 全部标记为 @MainActor，因为它们直接访问受主线程隔离的 sharedInstance
@MainActor
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
