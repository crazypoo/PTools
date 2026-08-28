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
    
    public static let defaultKey = "StatusBarState.default.root.key"
    
    open var isHidden = false
    open var style: UIStatusBarStyle = .default
    open var animation: UIStatusBarAnimation = .fade
    open var key = defaultKey
    
    open var subStates = [StatusBarState]()
    open weak var superState: StatusBarState?
    open weak var nextState: StatusBarState?
    
    public override var description: String {
        "{ key=\(key) selected=\(nextState?.key ?? "nil") }"
    }
}

/// 全局状态栏状态管理单例类
@MainActor
public class StatusBarManager {
    
    public static let shared = StatusBarManager()
    
    fileprivate var rootState: StatusBarState
    fileprivate var currentState: StatusBarState
    fileprivate var stateKeys = [String: StatusBarState]()
    fileprivate var duration: TimeInterval = 0.1
    
    private init() {
        // 初始化 rootState 和 currentState
        let initialState = StatusBarState()
        rootState = initialState
        currentState = initialState
        stateKeys[initialState.key] = initialState
    }
    
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
        guard stateKeys[key] == nil else { return nil }
        
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
        
        stateKeys[key] = newState
        return newState
    }
    
    public func removeState(with key: String) {
        guard let state = stateKeys[key], state != rootState else { return }
        
        let isCurrentStateContained = findStateInTree(state, key: currentState.key) != nil
        removeSubStatesInTree(state)
        
        state.superState?.subStates.removeAll { $0.key == key }
        state.superState?.nextState = state.superState?.subStates.first
        
        stateKeys.removeValue(forKey: key)
        state.superState = nil
        state.nextState = nil
        
        if isCurrentStateContained {
            currentState = state.superState?.nextState ?? state.superState ?? rootState
            updateStatusBar()
        }
    }
    
    public func showState(for key: String, root: String? = nil) {
        guard let rootState = findState(root), let targetState = findStateInTree(rootState, key: key) else { return }
        
        rootState.nextState = targetState
        if let newCurrentState = findCurrentStateInTree(rootState), newCurrentState != currentState {
            currentState = newCurrentState
            updateStatusBar()
        }
    }
    
    public func clearSubStates(with key: String, isUpdate: Bool = true) {
        guard let state = stateKeys[key] else { return }
        
        let shouldUpdate = findStateInTree(state, key: currentState.key) != nil
        removeSubStatesInTree(state)
        
        if shouldUpdate && isUpdate {
            currentState = state
            updateStatusBar()
        }
    }
    
    public func printAllStates(_ method: String = #function) {
        PTNSLogConsole("\(method): currentState = \(currentState.key)", levelType: PTLogMode, loggerType: .statusBar)
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
        // Update the active scene immediately to avoid stale asynchronous status-bar updates.
        // Actualiza la escena activa inmediatamente para evitar actualizaciones asíncronas obsoletas.
        // 立即更新当前场景，避免异步状态栏刷新使用过期状态。
        UIView.animate(withDuration: duration) {
            PTSceneContext.activeWindow()?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    fileprivate func findState(_ key: String? = nil) -> StatusBarState? {
        return key.flatMap { stateKeys[$0] } ?? rootState
    }
    
    fileprivate func findStateInTree(_ state: StatusBarState, key: String) -> StatusBarState? {
        if state.key == key {
            return state
        }
        return state.subStates.lazy.compactMap { self.findStateInTree($0, key: key) }.first
    }
    
    fileprivate func removeSubStatesInTree(_ state: StatusBarState) {
        let children = state.subStates
        state.subStates.removeAll()
        state.nextState = nil

        // Remove every descendant key, not only the direct child key.
        // Elimina todas las claves descendientes, no solo la clave del hijo directo.
        // 清理所有后代状态键，而不只是直接子节点的键。
        children.forEach { child in
            removeSubStatesInTree(child)
            stateKeys.removeValue(forKey: child.key)
            child.superState = nil
            child.nextState = nil
        }
    }
    
    fileprivate func findCurrentStateInTree(_ state: StatusBarState) -> StatusBarState? {
        var currentState = state
        while let nextState = currentState.nextState {
            currentState = nextState
        }
        return currentState
    }
    
    fileprivate func printAllStatesInTree(_ state: StatusBarState, deep: Int = 0, method: String) {
        PTNSLogConsole("\(method): \(deep) - state=\(state)", levelType: PTLogMode, loggerType: .statusBar)
        state.subStates.forEach { printAllStatesInTree($0, deep: deep + 1, method: method) }
    }
    
    // 在你的 StatusBarManager 或者类似的单例中
    public func update(with style: PTNavigationBarStyle) {
        switch style {
        case .gradient:
            self.style = .lightContent
        case .solid(let color):
            // 这里的 pt_colorTone 是你现有的逻辑
            self.style = color.pt_colorTone() == .dark ? .lightContent : .darkContent
        case .transparent:
            // 透明时可以根据业务逻辑，通常跟随背景色或默认 Dark
            self.style = .darkContent
        }
    }
}
