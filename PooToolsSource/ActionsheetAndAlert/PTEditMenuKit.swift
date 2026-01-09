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
        
        // 自动生成合法 ObjC Selector identifier
        if let id = identifier, PTEditMenuAction.isValidObjCSelector(id) {
            self.identifier = id
        } else {
            // 生成 pt_auto_随机UUID
            self.identifier = "pt_auto_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
    }
    
    private static func isValidObjCSelector(_ string: String) -> Bool {
        let pattern = "^[A-Za-z_][A-Za-z0-9_]*$"
        return string.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - PTEditMenuKit
@objcMembers
public final class PTEditMenuKit: NSObject {

    public weak var targetView: UIView?
    public var actions: [PTEditMenuAction]

    // iOS15
    fileprivate let legacyResponder = PTLegacyMenuResponder()

    // iOS16+
    private var editMenuInteraction: Any?

    public init(view: UIView, actions: [PTEditMenuAction]) {
        self.targetView = view
        self.actions = actions
        super.init()
        configure()
    }

    deinit {
        if #available(iOS 16.0, *),
           let interaction = editMenuInteraction as? UIEditMenuInteraction {
            targetView?.removeInteraction(interaction)
        }
    }

    private func configure() {
        targetView?.isUserInteractionEnabled = true
        if #available(iOS 16.0, *) {
            configureEditMenuInteraction()
        } else {
            configureLegacyMenu()
        }
    }

    public func present(from rect: CGRect) {
        guard let view = targetView,view.window != nil else { return }

        if #available(iOS 16.0, *) {
            let config = UIEditMenuConfiguration(identifier: nil, sourcePoint: CGPointMake(rect.midX, rect.midY))
            (editMenuInteraction as? UIEditMenuInteraction)?.presentEditMenu(with: config)
        } else {
            view.becomeFirstResponder()
            UIMenuController.shared.showMenu(from: view, rect: rect)
        }
    }
}

// MARK: - iOS 16+ UIEditMenuInteraction
@available(iOS 16.0, *)
extension PTEditMenuKit: UIEditMenuInteractionDelegate {

    private func configureEditMenuInteraction() {
        guard let view = targetView else { return }
        let interaction = UIEditMenuInteraction(delegate: self)
        view.addInteraction(interaction)
        editMenuInteraction = interaction
        
        // 自动延迟触发 present
        DispatchQueue.main.async { [weak self, weak view] in
            guard let self = self, let view = view, view.window != nil else { return }
            // 自动 sourcePoint 使用 view.bounds 中心
            let rect = view.bounds
            self.present(from: rect)
        }
    }

    public func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        guard !actions.isEmpty else { return UIMenu(title: "", children: []) }
        let children:[UIAction] = actions.map { action in
            UIAction(title: action.title,
                     image: action.image,
                     attributes: action.attributes) { _ in
                PTGCDManager.gcdMain(block: {
                    action.handler()
                })
            }
        }
        return UIMenu(title:"",children: children)
    }
}

// MARK: - iOS 15 Legacy (SAFE)
extension PTEditMenuKit {

    private func configureLegacyMenu() {
        legacyResponder.handlers.removeAll()

        actions.forEach { action in
            legacyResponder.handlers[action.identifier] = action.handler
        }

        let items = actions.map {
            UIMenuItem(title: $0.title, action: Selector($0.identifier))
        }

        UIMenuController.shared.menuItems = items
    }
}

// MARK: - Legacy Responder
@objcMembers
final class PTLegacyMenuResponder: NSObject {

    var handlers: [String: PTActionTask] = [:]

    override func responds(to aSelector: Selector!) -> Bool {
        handlers.keys.contains(NSStringFromSelector(aSelector))
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        guard let handler = handlers[NSStringFromSelector(aSelector)] else {
            return super.forwardingTarget(for: aSelector)
        }
        return PTLegacyMenuActionProxy(handler: handler)
    }
}

final class PTLegacyMenuActionProxy: NSObject {
    let handler: PTActionTask
    init(handler: @escaping PTActionTask) {
        self.handler = handler
    }

    @MainActor @objc func invoke(_ sender: Any?) {
        handler()
    }
}

// MARK: - UIView Helper (SAFE)
public extension UIView {

    func pt_bindEditMenu(actions: [PTEditMenuAction]) {
        let kit = PTEditMenuKit(view: self, actions: actions)
        objc_setAssociatedObject(self, &AssociatedKeys.menuKit, kit, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    override var canBecomeFirstResponder: Bool { true }
    
    /// ⭐️ 关键：EditMenu 是否「可执行」的最终判定
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool { return true }
}

private enum AssociatedKeys {
    static var menuKit = 999998
}
