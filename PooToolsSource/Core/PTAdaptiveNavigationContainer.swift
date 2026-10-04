//
//  PTAdaptiveNavigationContainer.swift
//  PooTools
//

import UIKit

// English: This small Core protocol lets Router discover an adaptive UIKit host without depending on SplitView.
// Español: Este protocolo pequeño de Core permite que Router descubra un host UIKit adaptativo sin depender de SplitView.
// 中文：这个轻量 Core 协议让 Router 可以发现自适应 UIKit 容器，同时不依赖 SplitView 模块。
@MainActor
public protocol PTAdaptiveNavigationContainer: AnyObject {
    func pt_showAdaptive(_ viewController: UIViewController)
}
