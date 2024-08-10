//
//  StatusBarManager.swift
//  Diou
//
//  Created by Jax on 2019/12/23.
//  Copyright © 2019 kooun. All rights reserved.
//

import Foundation
import UIKit

/// 状态栏单一状态节点
public class StatusBarState: NSObject {
    
    public static let defaultKey: String = "StatusBarState.default.root.key"
    
    open var isHidden: Bool = false
    open var style: UIStatusBarStyle = .default
    open var animation: UIStatusBarAnimation = .fade
    open var key: String = defaultKey
    
    open var subStates: [StatusBarState] = []
    open weak var superState: StatusBarState?
    open weak var nextState: StatusBarState?
    
    public override var description: String {
        "{ key=\(key) selected=\(String(describing: nextState?.key)) }"
    }
}

/// 全局状态栏状态管理单例类
public class StatusBarManager {
    
    public static let shared = StatusBarManager()
    
    fileprivate lazy var rootState: StatusBarState = {
        let state = StatusBarState()
        stateKeys.insert(state.key)
        return state
    }()
    
    fileprivate lazy var currentState: StatusBarState = rootState
    
    fileprivate var stateKeys: Set<String> = []
    fileprivate var duration: TimeInterval = 0.1
    
    open var isHidden: Bool {
        get { currentState.isHidden }
        set { setState(for: currentState.key, isHidden: newValue) }
    }
    
    open var style: UIStatusBarStyle {
        get { currentState.style }
        set { setState(for: currentState.key, style: newValue) }
    }
    
    open var animation: UIStatusBarAnimation {
        get { currentState.animation }
        set { setState(for: currentState.key, animation: newValue) }
    }
    
    @discardableResult
    public func addSubState(with key: String, root: String? = nil) -> StatusBarState? {
        guard !stateKeys.contains(key) else { return nil }
        
        let superState = findState(root) ?? rootState
        let newState = StatusBarState()
        newState.key = key
        newState.isHidden = superState.isHidden
        newState.style = superState.style
        newState.animation = superState.animation
        newState.superState = superState
        
        superState.subStates.append(newState)
        if superState.nextState == nil {
            superState.nextState = newState
        }
        
        if currentState.key == superState.key {
            currentState = newState
            updateStatusBar()
        }
        
        stateKeys.insert(key)
        return newState
    }
    
    public func removeState(with key: String) {
        guard let state = findState(key), state != rootState else { return }
        
        let isCurrentStateContained = findStateInTree(state, key: currentState.key) != nil
        removeSubStatesInTree(state)
        
        state.superState?.subStates.removeAll { $0.key == key }
        state.superState?.nextState = state.superState?.subStates.first
        
        stateKeys.remove(key)
        
        if isCurrentStateContained {
            currentState = state.superState?.nextState ?? state.superState ?? rootState
            updateStatusBar()
        }
    }
    
    public func showState(for key: String, root: String? = nil) {
        guard let rootState = findState(root), let targetState = findStateInTree(rootState, key: key) else { return }
        
        rootState.nextState = targetState
        let newCurrentState = findCurrentStateInTree(rootState)
        
        if newCurrentState != currentState {
            currentState = newCurrentState ?? rootState
            updateStatusBar()
        }
    }
    
    public func clearSubStates(with key: String, isUpdate: Bool = true) {
        guard let state = findState(key) else { return }
        
        let shouldUpdate = findStateInTree(state, key: currentState.key) != nil
        removeSubStatesInTree(state)
        
        if shouldUpdate && isUpdate {
            currentState = state
            updateStatusBar()
        }
    }
    
    public func printAllStates(_ method: String = #function) {
        PTNSLogConsole("\(method): currentState = \(currentState.key)", levelType: PTLogMode, loggerType: .StatusBar)
        printAllStatesInTree(rootState, deep: 0, method: method)
    }
    
    public func setState(for key: String? = nil, isHidden: Bool? = nil, style: UIStatusBarStyle? = nil, animation: UIStatusBarAnimation? = nil) {
        guard let state = findState(key) else { return }
        
        var needUpdate = false
        
        if let isHidden = isHidden, state.isHidden != isHidden {
            state.isHidden = isHidden
            needUpdate = true
        }
        if let style = style, state.style != style {
            state.style = style
            needUpdate = true
        }
        if let animation = animation, state.animation != animation {
            state.animation = animation
            needUpdate = true
        }
        
        if needUpdate && (key == nil || key == currentState.key) {
            updateStatusBar()
        }
    }
    
    fileprivate func updateStatusBar() {
        PTGCDManager.gcdMain {
            UIView.animate(withDuration: self.duration) {
                AppWindows?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    fileprivate func findState(_ key: String? = nil) -> StatusBarState? {
        return findStateInTree(rootState, key: key ?? rootState.key)
    }
    
    fileprivate func findStateInTree(_ state: StatusBarState, key: String) -> StatusBarState? {
        if state.key == key {
            return state
        }
        for subState in state.subStates {
            if let foundState = findStateInTree(subState, key: key) {
                return foundState
            }
        }
        return nil
    }
    
    fileprivate func removeSubStatesInTree(_ state: StatusBarState) {
        for subState in state.subStates {
            stateKeys.remove(subState.key)
            removeSubStatesInTree(subState)
        }
        state.subStates.removeAll()
    }
    
    fileprivate func findCurrentStateInTree(_ state: StatusBarState) -> StatusBarState? {
        return state.nextState.flatMap(findCurrentStateInTree) ?? state
    }
    
    fileprivate func printAllStatesInTree(_ state: StatusBarState, deep: Int = 0, method: String) {
        PTNSLogConsole("\(method): \(deep) - state=\(state)", levelType: PTLogMode, loggerType: .StatusBar)
        state.subStates.forEach { printAllStatesInTree($0, deep: deep + 1, method: method) }
    }
}
