//
//  StatusBarManager.swift
//  Diou
//
//  Created by 王锦发 on 2019/12/23.
//  Copyright © 2019 kooun. All rights reserved.
//

import Foundation
import UIKit

/// 状态栏单一状态节点
public class StatusBarState: NSObject {
    
    public static let defaultKey: String = "StatusBarState.default.root.key"
    
    var isHidden: Bool = false
    var style: UIStatusBarStyle = .default
    var animation: UIStatusBarAnimation = .fade
    var key: String = defaultKey
    // 子节点数组
    var subStates: [StatusBarState] = []
    // 父节点, 为 nil 说明是根节点
    weak var superState: StatusBarState?
    // 下一个路径节点，为 nil 说明是叶子节点
    weak var nextState: StatusBarState?
    
    public override var description: String {
        "{ key=\(key) selected=\(String(describing: nextState?.key)) }"
    }
    
}

/// 全局状态栏状态管理单例类
public class StatusBarManager {
    
    public static let shared = StatusBarManager()
    
    // MARK: - 属性
    /// 状态键集合，用来判断树中是否有某个状态
    fileprivate var stateKeys: Set<String> = Set<String>()
    /// 根节点状态，从这个根节点可以遍历到整个状态树
    fileprivate var rootState: StatusBarState!
    /// 更新状态栏动画时间
    fileprivate var duration: TimeInterval = 0.1
    /// 当前状态
    fileprivate var currentState: StatusBarState!
    
    /// 以下3个计算属性都是取当前状态显示以及更新当前状态
    public var isHidden: Bool {
        get {
            currentState.isHidden
        }
        set { setState(for: currentState.key, isHidden: newValue) }
    }
    public var style: UIStatusBarStyle {
        get {
            currentState.style
        }
        set { setState(for: currentState.key, style: newValue) }
    }
    public var animation: UIStatusBarAnimation {
        get {
            currentState.animation
        }
        set { setState(for: currentState.key, animation: newValue) }
    }
    
    // MARK: - 方法
    /// 初始化根节点
    fileprivate init() {
        rootState = StatusBarState()
        currentState = rootState
        stateKeys.insert(rootState.key)
    }
    
    /// 为某个状态(root)添加子状态(key)，当 root = nil 时，表示添加到根状态上
    @discardableResult
    public func addSubState(with key: String, root: String? = nil) -> StatusBarState? {
        
        guard !stateKeys.contains(key) else { return nil }
        stateKeys.insert(key)
        
        let newState = StatusBarState()
        newState.key = key
        
        // 找到键为 root 的父状态
        var superState: StatusBarState! = rootState
        if let root = root {
            superState = findState(root)
        }
        newState.isHidden = superState.isHidden
        newState.style = superState.style
        newState.animation = superState.animation
        newState.superState = superState
        
        // 添加进父状态的子状态集合中，默认选中第一个
        superState.subStates.append(newState)
        if superState.nextState == nil {
            superState.nextState = newState
        }
        
        // 判断是否在当前状态上添加子状态，是的话，自动切换当前状态
        if currentState.key == superState.key {
            currentState = newState
            updateStatusBar()
        }
        
//        printAllStates()
        return newState
        
    }
    
    /// 删除某个状态及其子状态树
    public func removeState(with key: String) {
        
        guard stateKeys.contains(key) else { return }
        let state = findState(key)
        let isContainCurrentState = findStateInTree(state, key: currentState.key) != nil
        if state.subStates.count > 0 {
            removeSubStatesInTree(state)
        }
        // 是否有父状态，如果没有，说明要删除的是根状态，根节点是不能删除的，否则删除该节点并切换当前状态
        if let superState = state.superState {
            stateKeys.remove(state.key)
            if let index = superState.subStates.firstIndex(of: state) {
                superState.subStates.remove(at: index)
            }
            superState.nextState = superState.subStates.first
            if isContainCurrentState {
                if let selectedState = superState.nextState {
                    currentState = selectedState
                } else {
                    currentState = superState
                }
                updateStatusBar()
            }
            
        }
//        printAllStates()
        
    }
    
    /// 更改某个状态(root)下要显示直接的子状态节点(key)
    public func showState(for key: String, root: String? = nil) {
        
        guard stateKeys.contains(key) else { return }
        
        // 改变父状态 nextState 属性
        let rootState = findState(root)
        for subState in rootState.subStates {
            if subState.key == key {
                rootState.nextState = subState
                break
            }
        }
        // 找到切换后的当前状态
        let newCurrentState = findCurrentStateInTree(rootState)
        if newCurrentState != currentState {
            currentState = newCurrentState
            updateStatusBar()
        }
//        printAllStates()
        
    }
    
    /// 删除某个状态下的子状态树
    public func clearSubStates(with key: String, isUpdate: Bool = true) {
        
        guard stateKeys.contains(key) else { return }
        let state = findState(key)
        var needUpdate: Bool = false
        if findStateInTree(state, key: currentState.key) != nil {
            currentState = state
            needUpdate = true
        }
        if state.subStates.count > 0 {
            removeSubStatesInTree(state)
        }
        if needUpdate && isUpdate {
            updateStatusBar()
        }
//        printAllStates()
        
    }
    
    /// 负责打印状态树结构
    public func printAllStates(_ method: String = #function) {
        debugPrint("\(method): currentState = \(currentState.key)")
        printAllStatesInTree(rootState, deep: 0, method: method)
    }
    
    /// 更新栈中 key 对应的状态，key == nil 表示栈顶状态
    public func setState(for key: String? = nil, isHidden: Bool? = nil, style: UIStatusBarStyle? = nil, animation: UIStatusBarAnimation? = nil) {
        
        var needUpdate: Bool = false
        let state = findState(key)
        if let isHidden = isHidden, state.isHidden != isHidden {
            needUpdate = true
            state.isHidden = isHidden
        }
        if let style = style, state.style != style {
            needUpdate = true
            state.style = style
        }
        if let animation = animation, state.animation != animation {
            needUpdate = true
            state.animation = animation
        }
        // key != nil 表示更新对应 key 的状态，需要判断该状态是否是当前状态
        if let key = key {
            guard let currentState = currentState, currentState.key == key else { return }
        }
        // 状态有变化才需要更新视图
        if needUpdate {
            updateStatusBar()
        }
        
    }
    
    /// 开始更新状态栏的状态
    fileprivate func updateStatusBar() {
        DispatchQueue.main.async { // 在主线程异步执行 避免同时索取同一属性
            // 如果状态栏需要动画（fade or slide），需要添加动画时间，才会有动画效果
            UIView.animate(withDuration: self.duration, animations: {
                AppWindows?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
//                UIApplication.shared.keyWindow?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            })
        }
    }
        
    /// 从状态树中找到对应的节点状态，没找到就返回根节点
    fileprivate func findState(_ key: String? = nil) -> StatusBarState {
        if let key = key { // 查找
            if let findState = findStateInTree(rootState, key: key) {
                return findState
            }
        }
        return rootState
    }
        
    /// 从状态树中找到对应的节点状态的递归方法
    fileprivate func findStateInTree(_ state: StatusBarState, key: String) -> StatusBarState? {
        if state.key == key {
            return state
        }
        for subState in state.subStates {
            if let findState = findStateInTree(subState, key: key) {
                return findState
            }
        }
        return nil
    }
        
    /// 删除某个状态下的所有子状态的递归方法
    fileprivate func removeSubStatesInTree(_ state: StatusBarState) {
        state.subStates.forEach { (subState) in
            stateKeys.remove(subState.key)
            removeSubStatesInTree(subState)
        }
        state.subStates.removeAll()
    }
        
    /// 找到某个状态下的最底层状态
    fileprivate func findCurrentStateInTree(_ state: StatusBarState) -> StatusBarState? {
        if let nextState = state.nextState {
            return findCurrentStateInTree(nextState)
        }
        return state
    }
        
    /// 打印状态树结构的递归方法
    fileprivate func printAllStatesInTree(_ state: StatusBarState, deep: Int = 0, method: String) {
        debugPrint("\(method): \(deep) - state=\(state)")
        for subState in state.subStates {
            printAllStatesInTree(subState, deep: deep + 1, method: method)
        }
    }
    
}
