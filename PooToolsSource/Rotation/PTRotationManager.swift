//
//  PTRotationManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 4/12/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Combine

// MARK: - 扩展通知名称，更规范的写法
public extension Notification.Name {
    static let PTRotationOrientationDidChange = Notification.Name("PTRotationOrientationDidChangeNotification")
    static let PTRotationLockOrientationDidChange = Notification.Name("PTRotationLockOrientationDidChangeNotification")
    static let PTRotationLockLandscapeDidChange = Notification.Name("PTRotationLockLandscapeDidChangeNotification")
}

// 必须限定在主线程运行，防止 UI 刷新引发 Crash
@MainActor
public final class PTRotationManager {
    
    // MARK: - 可旋转的屏幕方向【枚举】
    public enum Orientation: CaseIterable {
        case orientationPortrait       // 竖屏 手机头在上边
        case orientationLandscapeLeft  // 横屏 手机头在左边
        case orientationLandscapeRight // 横屏 手机头在右边
    }
    
    // MARK: - 属性
    /// 单例（严谨的单例模式：禁止外部初始化）
    public static let shared = PTRotationManager()
    
    /// 可否旋转
    public private(set) var isEnabled = true
    
    /// 当前屏幕方向（UIInterfaceOrientationMask）
    public private(set) var orientationMask: UIInterfaceOrientationMask = .portrait {
        didSet {
            guard orientationMask != oldValue else { return }
            publishOrientationMaskDidChange()
        }
    }
    
    /// 是否锁定屏幕方向
    public var isLockOrientationWhenDeviceOrientationDidChange = true {
        didSet {
            guard isLockOrientationWhenDeviceOrientationDidChange != oldValue else { return }
            publishLockOrientationWhenDeviceOrientationDidChange()
        }
    }
    
    /// 是否锁定横屏方向
    public var isLockLandscapeWhenDeviceOrientationDidChange = false {
        didSet {
            guard isLockLandscapeWhenDeviceOrientationDidChange != oldValue else { return }
            publishLockLandscapeWhenDeviceOrientationDidChange()
        }
    }
    
    /// 是否正在竖屏
    public var isPortrait: Bool { orientationMask == .portrait }
    
    /// 当前屏幕方向（`UIInterfaceOrientationMask` --> `ScreenRotator.Orientation`）
    public var orientation: Orientation {
        switch orientationMask {
        case .landscapeLeft:
            return .orientationLandscapeRight
        case .landscapeRight:
            return .orientationLandscapeLeft
        case .landscape:
            let deviceOrientation = UIDevice.current.orientation
            return deviceOrientation == .landscapeRight ? .orientationLandscapeRight : .orientationLandscapeLeft
        default:
            return .orientationPortrait
        }
    }
    
    // MARK: - 状态发生改变的【回调闭包】
    public var orientationMaskDidChange: ((_ orientationMask: UIInterfaceOrientationMask) -> Void)?
    public var lockOrientationWhenDeviceOrientationDidChange: ((_ isLock: Bool) -> Void)?
    public var lockLandscapeWhenDeviceOrientationDidChange: ((_ isLock: Bool) -> Void)?
    
    // MARK: - 构造器
    private init() { // 私有化 init，确保纯正的单例
        setupNotifications()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

// MARK: - 私有API
private extension PTRotationManager {
    
    static func convertInterfaceOrientationMaskToDeviceOrientation(_ orientationMask: UIInterfaceOrientationMask) -> UIDeviceOrientation {
        switch orientationMask {
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .landscape: return .landscapeLeft
        default: return .portrait
        }
    }

    static func convertDeviceOrientationToInterfaceOrientationMask(_ orientation: UIDeviceOrientation) -> UIInterfaceOrientationMask {
        switch orientation {
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return .portrait
        }
    }
    
    func rotation(to orientationMask: UIInterfaceOrientationMask) {
        guard isEnabled, self.orientationMask != orientationMask else { return }
        
        // 更新并广播屏幕方向
        self.orientationMask = orientationMask
        
        // 控制横竖屏
        if #available(iOS 16.0, *) {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientationMask)
            
            // 优化：使用 compactMap 安全解包并过滤
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            
            for windowScene in windowScenes {
                for window in windowScene.windows {
                    window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
                // 请求更新
                windowScene.requestGeometryUpdate(geometryPreferences)
            }
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
            
            let currentDevice = UIDevice.current
            let deviceOrientation = Self.convertInterfaceOrientationMaskToDeviceOrientation(orientationMask)
            currentDevice.setValue(NSNumber(value: deviceOrientation.rawValue), forKeyPath: "orientation")
        }
    }
}

// MARK: - 监听与广播通知
private extension PTRotationManager {
    @objc func willResignActive() { isEnabled = false }
    
    @objc func didBecomeActive() { isEnabled = true }
    
    @objc func deviceOrientationDidChange() {
        guard isEnabled, !isLockOrientationWhenDeviceOrientationDidChange else { return }
        
        let deviceOrientation = UIDevice.current.orientation
        guard deviceOrientation.isValidInterfaceOrientation else { return }
        
        if isLockLandscapeWhenDeviceOrientationDidChange, !deviceOrientation.isLandscape {
            return
        }
        
        let targetMask = Self.convertDeviceOrientationToInterfaceOrientationMask(deviceOrientation)
        rotation(to: targetMask)
    }
    
    func publishOrientationMaskDidChange() {
        orientationMaskDidChange?(orientationMask)
        NotificationCenter.default.post(name: .PTRotationOrientationDidChange, object: orientationMask)
    }
    
    func publishLockOrientationWhenDeviceOrientationDidChange() {
        lockOrientationWhenDeviceOrientationDidChange?(isLockOrientationWhenDeviceOrientationDidChange)
        NotificationCenter.default.post(name: .PTRotationLockOrientationDidChange,
                                        object: isLockOrientationWhenDeviceOrientationDidChange)
    }
    
    func publishLockLandscapeWhenDeviceOrientationDidChange() {
        lockLandscapeWhenDeviceOrientationDidChange?(isLockLandscapeWhenDeviceOrientationDidChange)
        NotificationCenter.default.post(name: .PTRotationLockLandscapeDidChange,
                                        object: isLockLandscapeWhenDeviceOrientationDidChange)
    }
}

// MARK: - 公开API
public extension PTRotationManager {
    func rotation(to orientation: Orientation) {
        let mask: UIInterfaceOrientationMask
        switch orientation {
        case .orientationLandscapeLeft: mask = .landscapeRight
        case .orientationLandscapeRight: mask = .landscapeLeft
        default: mask = .portrait
        }
        rotation(to: mask)
    }
    
    func rotationToPortrait() { rotation(to: .orientationPortrait) }
    
    func rotationToLandscape() {
        guard isEnabled else { return }
        let currentMask = Self.convertDeviceOrientationToInterfaceOrientationMask(UIDevice.current.orientation)
        rotation(to: currentMask == .portrait ? .landscapeRight : currentMask)
    }
    
    func rotationToLandscapeLeft() { rotation(to: .orientationLandscapeRight) }
    func rotationToLandscapeRight() { rotation(to: .orientationLandscapeLeft) }
    
    func toggleOrientation() {
        guard isEnabled else { return }
        let targetMask: UIInterfaceOrientationMask = orientationMask == .portrait ? .landscapeRight : .portrait
        rotation(to: targetMask)
    }
}

// MARK: - SwiftUI 状态管理
@MainActor
public class PTRotationManagerState: ObservableObject {
    @Published public var orientation: PTRotationManager.Orientation = PTRotationManager.shared.orientation {
        didSet {
            // 【重要修复】拦截内部触发的改变，防止与通知引起状态更新死循环
            guard orientation != PTRotationManager.shared.orientation else { return }
            PTRotationManager.shared.rotation(to: orientation)
        }
    }
    
    @Published public var isLockOrientation: Bool = PTRotationManager.shared.isLockOrientationWhenDeviceOrientationDidChange {
        didSet {
            guard isLockOrientation != PTRotationManager.shared.isLockOrientationWhenDeviceOrientationDidChange else { return }
            PTRotationManager.shared.isLockOrientationWhenDeviceOrientationDidChange = isLockOrientation
        }
    }
    
    @Published public var isLockLandscape: Bool = PTRotationManager.shared.isLockLandscapeWhenDeviceOrientationDidChange {
        didSet {
            guard isLockLandscape != PTRotationManager.shared.isLockLandscapeWhenDeviceOrientationDidChange else { return }
            PTRotationManager.shared.isLockLandscapeWhenDeviceOrientationDidChange = isLockLandscape
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // 使用 Combine 监听通知，比 #selector 更优雅，无需关心手动 removeObserver
        NotificationCenter.default.publisher(for: .PTRotationOrientationDidChange)
            .sink { [weak self] _ in
                self?.orientation = PTRotationManager.shared.orientation
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .PTRotationLockOrientationDidChange)
            .sink { [weak self] _ in
                self?.isLockOrientation = PTRotationManager.shared.isLockOrientationWhenDeviceOrientationDidChange
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .PTRotationLockLandscapeDidChange)
            .sink { [weak self] _ in
                self?.isLockLandscape = PTRotationManager.shared.isLockLandscapeWhenDeviceOrientationDidChange
            }
            .store(in: &cancellables)
    }
}
