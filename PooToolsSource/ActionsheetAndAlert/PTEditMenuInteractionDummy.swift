//
//  PTEditMenuInteractionDummy.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/19.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class PTEditMenuInteractionDummy: UIView {
    private var actions: Set<String>
    private var callback: (Selector) -> Void
    
    // 禁用的初始化方法
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @available(*, unavailable)
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    // 私有初始化方法
    private init(callback: @escaping (Selector) -> Void) {
        self.actions = Set()
        self.callback = callback
        super.init(frame: .zero)
    }
    
    // MARK: - Class method to create an instance
    static func dummy(callback: @escaping (Selector) -> Void) -> PTEditMenuInteractionDummy {
        return PTEditMenuInteractionDummy(callback: callback)
    }
    
    // MARK: - Update actions
    func updateActions(_ actions: Set<String>?) {
        guard let actions = actions else { return }
        self.actions = actions
    }
    
    // MARK: - Check if selector is supported
    private func isSelectorSupported(_ selector: Selector) -> Bool {
        let selectorString = NSStringFromSelector(selector)
        return actions.contains(selectorString)
    }
    
    @objc static func fake() { }
    
    // MARK: - Override methods
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return isSelectorSupported(action)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if isSelectorSupported(aSelector) {
            callback(aSelector)
            return nil
        }
        return super.forwardingTarget(for: aSelector)
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if isSelectorSupported(aSelector) {
            return true
        }
        return super.responds(to: aSelector)
    }    
}
