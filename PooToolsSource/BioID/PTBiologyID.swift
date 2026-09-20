//
//  PTBiologyID.swift
//  Diou
//
//  Created by ken lam on 2021/10/21.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import LocalAuthentication
import Security

@objc public enum PTBiometryStatus: Int {
    case none, touchID, faceID, opticID
}

private let kBiometryService = "PTBiometricsService"
private let kBiometryDomainStateKey = "PTBiometryDomainStateKey"

@MainActor
@objcMembers
public class PTBiometricsManager: NSObject {
    public static let shared = PTBiometricsManager()

    // 🌟 新增：保存当前的验证上下文，用于支持主动取消
    private var activeContext: LAContext?

    private override init() {
        super.init()
    }

    // MARK: - 1. 获取设备支持的生物识别类型 (同步计算属性)
    public var currentBiometryStatus: PTBiometryStatus {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return .none }
        switch context.biometryType {
        case .none: return .none
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        @unknown default: return .none
        }
    }

    // MARK: - 🌟 2. 新增：主动取消验证机制
    /// 可以在外部随时调用此方法，强制关闭弹出的生物识别验证框
    public func cancelAuthentication() {
        activeContext?.invalidate()
        activeContext = nil
    }

    // MARK: - 3. 开始生物识别验证 (Async / Await + 降级策略 + 特征变更检测)
    /// - Parameters:
    ///   - alertTitle: 弹窗标题
    ///   - allowSystemFallback: 🌟 是否允许系统级的锁屏密码降级。传 false 则返回给 App 自行处理。
    public func startAuthentication(alertTitle: String = "生物识别验证", allowSystemFallback: Bool = true) async -> PTBiologyVerifyStatus {
        
        let context = LAContext()
        self.activeContext = context // 记录活动 Context 以备取消
        context.localizedReason = alertTitle
        
        // 降级控制：如果设为 false，可以把 fallback 按钮隐藏，或改为你想要的文字
        context.localizedFallbackTitle = allowSystemFallback ? "" : "使用其他方式登录"

        do {
            // 🔥 魔法开始：直接 await 系统 API，无需闭包！
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: alertTitle)
            
            // 🌟 新增：生物特征变更检测 (Domain State)
            if success, let domainState = context.evaluatedPolicyDomainState {
                let savedState = UserDefaults.standard.data(forKey: kBiometryDomainStateKey)
                if let saved = savedState, saved != domainState {
                    // 发现特征被修改（例如坏人添加了自己的指纹），拦截并返回警告！
                    UserDefaults.standard.set(domainState, forKey: kBiometryDomainStateKey)
                    return .domainStateChanged
                }
                // 首次验证成功，记录当前生物特征的状态
                UserDefaults.standard.set(domainState, forKey: kBiometryDomainStateKey)
            }
            
            return success ? .success : .unknown
            
        } catch let error as LAError {
            // 系统标准的生物识别错误拦截
            return await handleLAError(error, context: context, reason: alertTitle, allowSystemFallback: allowSystemFallback)
        } catch {
            return .unknown
        }
    }

    // MARK: - 4. 错误处理提取 (Async)
    private func handleLAError(_ error: LAError, context: LAContext, reason: String, allowSystemFallback: Bool) async -> PTBiologyVerifyStatus {
        switch error.code {
        case .systemCancel, .appCancel:
            return .systemCancel // 注：调用 cancelAuthentication() 触发的 invalidate() 会走 .appCancel
        case .userCancel:
            return .alertCancel
        case .authenticationFailed:
            return .failed
        case .passcodeNotSet:
            return .keyboardIDNotFound
        case .biometryNotAvailable:
            return .touchIDNotOpen
        case .biometryNotEnrolled:
            return .touchIDNotFound
        case .userFallback:
            if allowSystemFallback {
                // 如果允许系统降级，继续 await 系统的密码验证
                return await fallbackToPassword(context: context, reason: reason)
            } else {
                // 如果不允许，直接把状态抛给上层，让 App 自己弹出密码输入框
                return .keyboardTouchID
            }
        default:
            return .unknown
        }
    }

    private func fallbackToPassword(context: LAContext, reason: String) async -> PTBiologyVerifyStatus {
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            return success ? .success : .keyboardCancel
        } catch {
            return .keyboardCancel
        }
    }

    // MARK: - 🌟 5. 钥匙串操作 (Async / Await + 脱离主线程防卡顿)
    public func saveAccount(_ reason: String = "保存账号密码需要验证", account: String, password: String) async -> Bool {
        guard let _ = password.data(using: .utf8) else { return false }
        let context = LAContext()
        context.localizedReason = reason
        let accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, nil)
        
        // English: Keep LAContext and its Keychain access on MainActor; they are not Sendable system objects.
        // Español: Mantiene LAContext y el acceso al Keychain en MainActor; son objetos del sistema no Sendable.
        // 中文：LAContext 与 Keychain 访问保持在 MainActor，因为它们是不可跨 actor 传递的系统对象。
        return PTKeyChain.saveAccountInfo(
            service: kBiometryService.nsString,
            account: account.nsString,
            password: password.nsString,
            context: context,
            accessControl: accessControl
        )
    }

    public func readPassword(for account: String, reason: String = "需要验证才能读取密码") async -> String? {
        let context = LAContext()
        context.localizedReason = reason

        // English: Do not capture LAContext in an unstructured detached task; keep its lifetime actor-bound.
        // Español: No captura LAContext en una tarea detached no estructurada; conserva su ciclo de vida en el actor.
        // 中文：不要在非结构化 detached 任务中捕获 LAContext，让它的生命周期保持在 actor 内。
        return PTKeyChain.getPassword(service: kBiometryService.nsString,
                                      account: account.nsString,
                                      context: context)
    }

    // MARK: - 6. 适配基于闭包的旧方法 (withCheckedContinuation)
    public func deleteBiometryID(account: String? = nil) async -> PTBiologyVerifyStatus {
        // English: Bridge the legacy callback without creating an extra global-queue hop.
        // Español: Puentea el callback heredado sin crear un salto adicional a una cola global.
        // 中文：桥接旧回调时不再额外跳转到全局队列。
        return await withCheckedContinuation { continuation in
            PTKeyChain.deleteAccountInfo(service: kBiometryService.nsString, account: (account ?? "").nsString) { _, status in
                continuation.resume(returning: status)
            }
        }
    }
}
