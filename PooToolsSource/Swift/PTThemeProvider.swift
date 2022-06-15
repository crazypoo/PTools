//
//  JKThemeProvider.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation
import UIKit

// MARK: - PTThemeProvider协议
public protocol PTThemeProvider: AnyObject {
    func register<Observer: PTThemeable>(observer: Observer)
    func updateTheme()
}

// MARK: - PTThemeable协议
public protocol PTThemeable: AnyObject {
    func apply()
}

// MARK: - 设置遵守UITraitEnvironment的可以使用协议PTThemeable
public extension PTThemeable where Self: UITraitEnvironment {
    var themeProvider: PTThemeProvider {
        return LegacyThemeProvider.shared
    }
}

// MARK: - LegacyThemeProvider
public class LegacyThemeProvider: PTThemeProvider {
    
    /// 单粒
    static let shared = LegacyThemeProvider()
    /// 监听对象数组
    private var observers: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    /// 更新主题
    public func updateTheme() {
        notifyObservers()
    }
    
    // MARK: 注册监听
    /// 注册监听
    /// - Parameter observer: 监听对象
    public func register<Observer: PTThemeable>(observer: Observer) {
        if #available(iOS 13.0, *) {
            return
        }
        self.observers.add(observer)
    }
    
    // MARK: 通知监听对象更新theme
    /// 通知监听对象更新theme
    private func notifyObservers() {
        PTUtils.gcdMain {
            self.observers.allObjects
                .compactMap({ $0 as? PTThemeable })
                .forEach({ $0.apply() })
        }
    }
}

