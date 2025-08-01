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

@objcMembers
public class PTEditMenuItemsInteraction: NSObject {
    public static let share = PTEditMenuItemsInteraction()
    private var showingItems: [PTEditMenuItem]?
    private var targetRect: CGRect?
    private let seperator = "_"
    // iOS 16之前使用官方的UIMenuController
    private lazy var menuController: UIMenuController = .shared
    
    @MainActor private lazy var dummyView: PTEditMenuInteractionDummy = {
        let view = PTEditMenuInteractionDummy.dummy { selector in
            self.selectMenuItem(selector)
        }
        return view
    }()
    
    // iOS 16之后使用官方的UIEditMenuInteraction
    private lazy var rawMenuInteraction: Any? = {
        if #available(iOS 16, *) {
            return MainActor.assumeIsolated {
                UIEditMenuInteraction(delegate: self)
            }
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
        PTGCDManager.gcdMain { [weak self] in
            self?.clear()
        }
    }
    
    // MARK: public function
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(willMenuControllerHide(_:)), name: UIMenuController.willHideMenuNotification, object: nil)
    }
    
    //MARK: 显示menu
    ///显示menu
    /// - Parameters:
    ///   - items: Model
    ///   - rect: 相对于interactionView的一个rect，一般为希望显示menu的selection的最小包围矩形
    ///   - targetRect:
    ///   - view: 须要展示在x View上
    @MainActor public func showMenu(_ items: [PTEditMenuItem], targetRect: CGRect, for view: UIView) {
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
            
            dummyView.removeFromSuperview()

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
    
    @MainActor public func dismissMenu() {
        if #available(iOS 16, *) {
            menuInteraction?.dismissMenu()
        } else {
            menuController.hideMenu()
        }
        clear()
    }
    
    /// 选中某个menuitem时执行。该方法仅在iOS 16之前会执行
    @MainActor func selectMenuItem(_ selector: Selector) {
        guard let item = menuItem(from: selector) else { return }
        item.callback?()
    }
    
    // MARK: private function
    
    @MainActor @objc private func willMenuControllerHide(_: Notification) {
        guard let _ = showingItems else { return }
        clear()
    }
    
    @MainActor private func clear() {
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
    
    @MainActor private func menuItems(from items: [PTEditMenuItem]) -> [UIMenuItem] {
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
    
    @MainActor private func selector(from _: PTEditMenuItem, index: Int) -> Selector {
        let selectorString = "selectMenuItem\(seperator)\(index)"
        let selector = Selector(selectorString)
        
        // 动态添加方法到当前类
        if !responds(to: selector) {
            let implementation: @convention(block) (Any) -> Void = { [weak self] _ in
                self?.selectMenuItem(selector)
            }
            let imp = imp_implementationWithBlock(implementation)
            class_addMethod(PTEditMenuInteractionDummy.self, selector, imp, "v@:@")
        }
        
        return selector
    }
        
    @MainActor private func actionsForDummyView(_ items: [PTEditMenuItem]) -> Set<String> {
        var set = Set<String>()
        items.enumerated().forEach {
            set.insert(NSStringFromSelector(selector(from: $0.element, index: $0.offset)))
        }
        return set
    }
}

// MARK: UIEditMenuInteractionDelegate
extension PTEditMenuItemsInteraction: @MainActor UIEditMenuInteractionDelegate {
    @available(iOS 16.0, *)
    public func editMenuInteraction(_: UIEditMenuInteraction, targetRectFor _: UIEditMenuConfiguration) -> CGRect {
        guard let rect = targetRect else {
            return .zero
        }
        return rect
    }
    
    @available(iOS 16.0, *)
    @MainActor public func editMenuInteraction(_: UIEditMenuInteraction, menuFor _: UIEditMenuConfiguration, suggestedActions _: [UIMenuElement]) -> UIMenu? {
        // items -> UIMenu
        guard let items = showingItems else { return nil }
        let actions = items.map { action(from: $0) }
        return UIMenu(children: actions)
    }
    
    @MainActor func action(from item: PTEditMenuItem) -> UIAction {
        UIAction(title: item.title) { _ in
            item.callback?()
        }
    }
}

