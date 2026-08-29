//
//  SSBlurView.swift
//  SpeedySwift
//
//  Created by 2020 on 2021/8/2.
//

import UIKit
import SnapKit

/// 高斯模糊视图 (重构为标准的 UIView 子类)
@objcMembers
public class SSBlurView: UIView {

    private let blurEffectView = UIVisualEffectView(effect: nil)
    private let vibrancyView = UIVisualEffectView(effect: nil)
    private var isBlurEnabled = false
    private var animationDurationStorage: TimeInterval = 0.2
    
    public var animationDuration: TimeInterval {
        get { animationDurationStorage }
        set {
            animationDurationStorage = newValue.isFinite ? max(0, newValue) : 0.2
        }
    }
    public var style: UIBlurEffect.Style = .systemMaterial {
        didSet { updateBlurEffect() }
    }
    
    // 暴露内容视图供外部添加子视图
    public var blurContentView: UIView { blurEffectView.contentView }
    public var vibrancyContentView: UIView { vibrancyView.contentView }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        self.isUserInteractionEnabled = false // 默认不拦截事件
        self.isAccessibilityElement = false
        
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        blurEffectView.contentView.addSubview(vibrancyView)
        vibrancyView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // English: Observe Reduce Motion once and keep the effect state stable when accessibility settings change.
        // Español: Observa Reduce Motion una vez y conserva estable el estado del efecto cuando cambia la accesibilidad.
        // 中文：只注册一次减弱动态效果监听，保证辅助功能设置变化时模糊状态稳定。
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reduceMotionStatusDidChange),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil)
    }
    
    /// 开启模糊效果 (带动画)
    public func enable(animated: Bool = true) {
        isBlurEnabled = true
        setBlurEffect(enabled: true, animated: animated)
    }
    
    /// 关闭模糊效果 (带动画)
    public func disable(animated: Bool = true) {
        isBlurEnabled = false
        setBlurEffect(enabled: false, animated: animated)
    }

    private func updateBlurEffect() {
        guard isBlurEnabled else { return }
        setBlurEffect(enabled: true, animated: true)
    }

    private func setBlurEffect(enabled: Bool, animated: Bool) {
        let targetEffect = enabled ? UIBlurEffect(style: style) : nil
        let shouldAnimate = animated && animationDurationStorage > 0 && !UIAccessibility.isReduceMotionEnabled

        // English: Remove the previous transition before starting a new one to avoid stacked visual-effect animations.
        // Español: Elimina la transición anterior antes de iniciar otra para evitar animaciones acumuladas del efecto visual.
        // 中文：开始新过渡前先移除旧动画，避免视觉效果动画叠加和状态错乱。
        blurEffectView.layer.removeAllAnimations()
        vibrancyView.layer.removeAllAnimations()

        if enabled {
            guard let targetEffect else { return }
            vibrancyView.effect = UIVibrancyEffect(blurEffect: targetEffect)
        }

        guard shouldAnimate else {
            blurEffectView.effect = targetEffect
            if !enabled {
                vibrancyView.effect = nil
            }
            return
        }

        UIView.animate(withDuration: animationDurationStorage,
                       delay: 0,
                       options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
            self.blurEffectView.effect = targetEffect
            if !enabled {
                self.vibrancyView.effect = nil
            }
        }
    }

    @objc private func reduceMotionStatusDidChange() {
        guard isBlurEnabled else { return }
        setBlurEffect(enabled: true, animated: false)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            blurEffectView.layer.removeAllAnimations()
            vibrancyView.layer.removeAllAnimations()
        } else if isBlurEnabled {
            setBlurEffect(enabled: true, animated: false)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                   name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                                   object: nil)
    }
}
