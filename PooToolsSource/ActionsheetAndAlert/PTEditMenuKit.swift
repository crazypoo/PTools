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
public struct PTEditMenuAction: @unchecked Sendable {
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
@MainActor
@objcMembers
public final class PTEditMenuKit: NSObject {

    public weak var targetView: UIView?
    public var actions: [PTEditMenuAction]

    // iOS 15 传统的 Responder 代理
    fileprivate let legacyResponder = PTLegacyMenuResponder()

    // iOS 16+ 使用 Any 避免低版本找不到类型声明
    private var editMenuInteraction: Any?

    public init(view: UIView, actions: [PTEditMenuAction]) {
        self.targetView = view
        self.actions = actions
        super.init()
        configure()
    }

    deinit {
//        // deinit 默认是非隔离的 (nonisolated)，若要访问 MainActor 属性需特殊处理或捕获
//        if #available(iOS 16.0, *) {
//            let interactionObj = editMenuInteraction
//            let viewObj = targetView
//            Task { @MainActor [interactionObj, viewObj] in
//                if let interaction = interactionObj as? UIEditMenuInteraction {
//                    viewObj?.removeInteraction(interaction)
//                }
//            }
//        }
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
        guard let view = targetView, view.window != nil else { return }

        if #available(iOS 16.0, *) {
            let config = UIEditMenuConfiguration(identifier: nil, sourcePoint: CGPoint(x: rect.midX, y: rect.midY))
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
        
        // Swift 6 推荐的异步主线程调用方式，替代 DispatchQueue.main.async
        Task { @MainActor [weak self, weak view] in
            guard let self = self, let view = view, view.window != nil else { return }
            let rect = view.bounds
            self.present(from: rect)
        }
    }

    nonisolated public func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        // Delegate 方法默认由 UIKit 在主线程调用，但在协议要求下需显式桥接回 MainActor 保证数据安全
        MainActor.assumeIsolated {
            guard !actions.isEmpty else { return UIMenu(title: "", children: []) }
            let children: [UIAction] = actions.map { action in
                UIAction(title: action.title,
                         image: action.image,
                         attributes: action.attributes) { _ in
                    // 已经是主线程安全，直接调用
                    action.handler()
                }
            }
            return UIMenu(title: "", children: children)
        }
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

final class PTLegacyMenuActionProxy: NSObject,@unchecked Sendable {
    let handler: PTActionTask
    init(handler: @escaping PTActionTask) {
        self.handler = handler
    }

    @objc func invoke(_ sender: Any?) {
        handler()
    }
}

// MARK: - AssociatedKeys (Swift 6 并发安全静态变量)
@MainActor
private enum AssociatedKeys {
    static var menuKit: UInt8 = 0
}

// MARK: - UIView Helper
public extension UIView {

    @MainActor
    func pt_bindEditMenu(actions: [PTEditMenuAction]) {
        let kit = PTEditMenuKit(view: self, actions: actions)
        // 传递安全的指针地址
        withUnsafePointer(to: &AssociatedKeys.menuKit) { pointer in
            objc_setAssociatedObject(self, pointer, kit, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /*
     直接在 extension 中 override `canBecomeFirstResponder` 和 `canPerformAction` 会影响全局所有 UIView。
     如果将来遇到系统输入框或按钮行为异常，建议取消这里的全局覆盖，改为在具体的 UIView 子类中重写这两个方法。
     */
    @MainActor
    @objc override var canBecomeFirstResponder: Bool { true }
    
    @MainActor
    @objc override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return true
    }
}
