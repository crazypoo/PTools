//
//  PTEditMenuItemsInteraction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTEditMenuItem:NSObject {
    var title: String = ""
    var callback: PTActionTask?
    
    public init(title: String, callback: PTActionTask? = nil) {
        self.title = title
        self.callback = callback
    }
}

public class PTEditMenuItemsInteraction: NSObject {
    private var showingItems: [PTEditMenuItem]?
    private var targetRect: CGRect?
    private let seperator = "_"
    // iOS 16之前使用官方的UIMenuController
    private lazy var menuController: UIMenuController = .shared

    private lazy var dummyView: PTEditMenuInteractionDummy = {
        let view = PTEditMenuInteractionDummy { selector in
            self.selectMenuItem(selector)
        }
        return view
    }()

    // iOS 16之后使用官方的UIEditMenuInteraction
    private lazy var rawMenuInteraction: Any? = {
        if #available(iOS 16, *) {
            return UIEditMenuInteraction(delegate: self) as Any
        }
        return nil
    }()

    @available(iOS 16, *)
    private var menuInteraction: UIEditMenuInteraction? {
        get {
            rawMenuInteraction as? UIEditMenuInteraction
        }
        set {
            rawMenuInteraction = newValue
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        clear()
    }

    // MARK: public function

    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(willMenuControllerHide(_:)), name: UIMenuController.willHideMenuNotification, object: nil)
    }

    /// 显示menu
    /// - Parameters:
    ///   - items:
    ///   - rect: 相对于interactionView的一个rect，一般为希望显示menu的selection的最小包围矩形
    ///   - indexPath:
    public func showMenu(_ items: [PTEditMenuItem], targetRect: CGRect, for view: UIView) {
        guard !items.isEmpty else { return }

        showingItems = items
        self.targetRect = targetRect

        if #available(iOS 16, *) {
            guard let menuInteraction = menuInteraction else { return }
            view.addInteraction(menuInteraction)
            let config = UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero)
            menuInteraction.presentEditMenu(with: config)
        } else {
            menuController.menuItems = nil
            menuController.hideMenu()

            dummyView.updateActions(actionsForDummyView(items))
            view.addSubview(dummyView)
            dummyView.frame = view.bounds

            dummyView.becomeFirstResponder()
            PTGCDManager.gcdMain {
                self.menuController.menuItems = self.menuItems(from: items)
                self.menuController.showMenu(from: self.dummyView, rect: targetRect)
            }
        }
    }

    public func dismissMenu() {
        if #available(iOS 16, *) {
            menuInteraction?.dismissMenu()
        } else {
            menuController.hideMenu()
        }
        clear()
    }

    /// 选中某个menuitem时执行。该方法仅在iOS 16之前会执行
    func selectMenuItem(_ selector: Selector) {
        guard let item = menuItem(from: selector) else { return }
        item.callback?()
    }

    // MARK: private function

    @objc private func willMenuControllerHide(_: Notification) {
        guard let _ = showingItems else { return }
        clear()
    }

    private func clear() {
        if #available(iOS 16, *) {
        } else {
            if let _ = showingItems {
                menuController.menuItems = nil
                dummyView.removeFromSuperview()
            }
        }
        showingItems = nil
        targetRect = nil
    }

    private func menuItems(from items: [PTEditMenuItem]) -> [UIMenuItem] {
        items.enumerated().compactMap {
            let item = $0.element
            return UIMenuItem(title: item.title, action: selector(from: item, index: $0.offset))
        }
    }

    private func menuItem(from selector: Selector) -> PTEditMenuItem? {
        let selectorString = NSStringFromSelector(selector) as String
        let cmps = selectorString.components(separatedBy: seperator)
        guard let items = showingItems, cmps.count == 2, let index = Int(cmps[1])
        else {  return nil }
        return items[index]
    }

    private func selector(from _: PTEditMenuItem, index: Int) -> Selector {
        // selector产生规则
        return Selector("clickMenuItem\(seperator)\(index)")
    }

    private func actionsForDummyView(_ items: [PTEditMenuItem]) -> Set<String> {
        var set = Set<String>()
        items.enumerated().forEach {
            set.insert(NSStringFromSelector(selector(from: $0.element, index: $0.offset)))
        }
        return set
    }
}

// MARK: UIEditMenuInteractionDelegate
extension PTEditMenuItemsInteraction: UIEditMenuInteractionDelegate {
    @available(iOS 16.0, *)
    public func editMenuInteraction(_: UIEditMenuInteraction, targetRectFor _: UIEditMenuConfiguration) -> CGRect {
        guard let rect = targetRect else {
            return .zero
        }
        return rect
    }

    @available(iOS 16.0, *)
    public func editMenuInteraction(_: UIEditMenuInteraction, menuFor _: UIEditMenuConfiguration, suggestedActions _: [UIMenuElement]) -> UIMenu? {
        // items -> UIMenu
        guard let items = showingItems else { return nil }
        let actions = items.map {
            action(from: $0)
        }
        return UIMenu(children: actions)
    }
    
    func action(from item: PTEditMenuItem) -> UIAction {
        return UIAction(title: item.title) { _ in
            item.callback?()
        }
    }
}
