//
//  PTEditMenuKit.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import ObjectiveC.runtime

// MARK: - PTEditMenuAction
public struct PTEditMenuAction {
    public let title: String
    public let image: UIImage?
    public let identifier: String
    public let attributes: UIMenuElement.Attributes
    public let handler: PTActionTask

    public init(title: String,
                image: UIImage? = nil,
                identifier: String? = nil,
                attributes: UIMenuElement.Attributes = [],
                handler: @escaping PTActionTask) {
        self.title = title
        self.image = image
        self.attributes = attributes
        self.handler = handler
        self.identifier = identifier.flatMap(Self.validIdentifier)
            ?? "pt_auto_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    private static func validIdentifier(_ value: String) -> String? {
        let pattern = "^[A-Za-z_][A-Za-z0-9_]*$"
        return value.range(of: pattern, options: .regularExpression) == nil ? nil : value
    }
}

// MARK: - PTEditMenuKit
@MainActor
@objcMembers
public final class PTEditMenuKit: NSObject {

    public weak var targetView: UIView?
    public var actions: [PTEditMenuAction] {
        didSet { presentCurrentMenuIfPossible() }
    }

    private var editMenuInteraction: UIEditMenuInteraction?

    public init(view: UIView, actions: [PTEditMenuAction]) {
        targetView = view
        self.actions = actions
        super.init()
        configure()
    }

    public func present(from rect: CGRect) {
        guard let view = targetView, view.window != nil else { return }
        let config = UIEditMenuConfiguration(
            identifier: nil,
            sourcePoint: CGPoint(x: rect.midX, y: rect.midY)
        )
        editMenuInteraction?.presentEditMenu(with: config)
    }
}

@available(iOS 16.0, *)
extension PTEditMenuKit: UIEditMenuInteractionDelegate {

    private func configure() {
        guard let view = targetView else { return }
        view.isUserInteractionEnabled = true
        let interaction = UIEditMenuInteraction(delegate: self)
        view.addInteraction(interaction)
        editMenuInteraction = interaction
        presentCurrentMenuIfPossible()
    }

    private func presentCurrentMenuIfPossible() {
        guard let view = targetView, view.window != nil else { return }
        present(from: view.bounds)
    }

    nonisolated public func editMenuInteraction(_ interaction: UIEditMenuInteraction,
                                                menuFor configuration: UIEditMenuConfiguration,
                                                suggestedActions: [UIMenuElement]) -> UIMenu? {
        // UIKit 的 EditMenu delegate 在主线程回调；非主线程直接忽略，避免强制切换导致崩溃。
        guard Thread.isMainThread else { return nil }
        return MainActor.assumeIsolated {
            guard !actions.isEmpty else { return nil }
            let children = actions.map { action in
                UIAction(
                    title: action.title, image: action.image, identifier: UIAction.Identifier(rawValue: action.identifier),
                    attributes: action.attributes
                ) { _ in
                    action.handler()
                }
            }
            return UIMenu(title: "", children: children)
        }
    }
}

// MARK: - Associated object
@MainActor
private enum AssociatedKeys {
    static var menuKit: UInt8 = 0
}

public extension UIView {

    @MainActor
    func pt_bindEditMenu(actions: [PTEditMenuAction]) {
        withUnsafePointer(to: &AssociatedKeys.menuKit) { pointer in
            if let kit = objc_getAssociatedObject(self, pointer) as? PTEditMenuKit {
                kit.actions = actions
                return
            }

            let kit = PTEditMenuKit(view: self, actions: actions)
            objc_setAssociatedObject(self, pointer, kit, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
