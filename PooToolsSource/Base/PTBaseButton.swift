//
//  PTBaseButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/9/23.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

// English: Button configuration and loading state are UI mutations owned by MainActor.
// Español: La configuración y el estado de carga del botón son mutaciones de UI propiedad de MainActor.
// 中文：按钮配置和加载状态属于 UI 修改，由 MainActor 统一持有。
@MainActor
open class PTBaseButton: UIButton {
    
    // MARK: - 私有 UI 组件
    // 懒加载传统的菊花指示器，仅在未使用 Configuration 时作为兜底方案介入
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isUserInteractionEnabled = false
        return indicator
    }()

    private var loadingIndicatorColor: UIColor = .white
    private lazy var loadingCoordinator = PTControlLoadingCoordinator(
        isInteractionEnabled: { [weak self] in self?.isUserInteractionEnabled ?? false },
        setInteractionEnabled: { [weak self] isEnabled in self?.isUserInteractionEnabled = isEnabled },
        beginPresentation: { [weak self] in self?.applyLoadingPresentation() },
        endPresentation: { [weak self] in self?.restoreLoadingPresentation() }
    )

    public var isLoading: Bool { loadingCoordinator.isLoading }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.expandClickEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        if #available(iOS 26.0, *) {
            if PTAppBaseConfig.share.navBarButton26Mode {
                configuration = UIButton.Configuration.clearGlass()
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 🚀 状态控制 API
        
    /// 开始等待动画
    /// - Parameter indicatorColor: 菊花的颜色（仅在非 Configuration 模式下生效）
    public func startLoading(indicatorColor: UIColor = .white) {
        loadingIndicatorColor = indicatorColor
        _ = loadingCoordinator.start()
    }

    private func applyLoadingPresentation() {
        // English: Prefer UIButton.Configuration when the caller already uses it.
        // Español: Usa UIButton.Configuration cuando el botón ya la tiene configurada.
        // 中文：如果调用方已经使用 UIButton.Configuration，则优先使用系统指示器。
        if var currentConfig = configuration {
            currentConfig.showsActivityIndicator = true
            configuration = currentConfig
            return
        }

        if activityIndicator.superview == nil {
            addSubview(activityIndicator)
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
        }
        
        activityIndicator.color = loadingIndicatorColor
        activityIndicator.startAnimating()
        
        // 柔和地隐藏原有内容，避免与菊花重叠重影
        UIView.animate(withDuration: PTUIAccessibility.animationDuration(0.2)) {
            self.titleLabel?.alpha = 0
            self.imageView?.alpha = 0
        }
    }
    
    /// 停止等待动画，恢复常态
    public func stopLoading() {
        loadingCoordinator.stop()
    }

    private func restoreLoadingPresentation() {
        // English: Restore the same presentation path that started loading.
        // Español: Restaura la misma ruta de presentación que inició la carga.
        // 中文：沿用进入 loading 时的展示路径恢复按钮内容。
        if var currentConfig = configuration {
            currentConfig.showsActivityIndicator = false
            configuration = currentConfig
            return
        }

        activityIndicator.stopAnimating()
        
        UIView.animate(withDuration: PTUIAccessibility.animationDuration(0.2)) {
            self.titleLabel?.alpha = 1
            self.imageView?.alpha = 1
        }
    }

    /// English: Runs one cancellable MainActor operation while preventing duplicate taps.
    /// Español: Ejecuta una operación cancelable en MainActor y evita toques duplicados.
    /// 中文：在 MainActor 中执行可取消操作，并防止重复点击。
    @discardableResult
    public func performAsync(_ operation: @escaping @MainActor @Sendable () async throws -> Void,
                             completion: @escaping @MainActor @Sendable (Bool) -> Void = { _ in }) -> Task<Void, Never> {
        loadingCoordinator.perform(operation, completion: completion)
    }

    public func cancelLoading() {
        loadingCoordinator.cancel()
    }

}
