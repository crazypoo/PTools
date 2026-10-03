//
//  PTTabBarMediaContent.swift
//  PooTools
//
//  English: Tab-bar media rendering is isolated from the tab-bar container.
//  Español: La representación multimedia de la barra de pestañas está aislada del contenedor.
//  中文：将标签栏媒体渲染职责从标签栏容器中独立出来。
//

import UIKit
import Lottie
import SnapKit
#if canImport(PToolsCore)
import PToolsCore
#endif

@MainActor
final public class PTTabBarImageContent: @MainActor PTTabBarItemContent {

    private let container = UIView()
    private let imageView = UIImageView()
    private let lottieView = LottieAnimationView()

    private let normalImage: Any
    private let selectedImage: Any?
    private let appearance: PTTabBarAppearance
    private var lottieLoadTask: Task<Void, Never>?
    private var mediaGeneration = 0

    public init(normal: Any,
                selected: Any? = nil,
                appearance: PTTabBarAppearance = .legacyDefault) {
        self.normalImage = normal
        self.selectedImage = selected
        self.appearance = appearance
        container.isUserInteractionEnabled = false
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit

        container.addSubviews([imageView, lottieView])
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        lottieView.isHidden = true
        lottieView.loopMode = .autoReverse
        lottieView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reduceMotionStatusDidChange),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil)
    }

    public var view: UIView { container }

    @MainActor public func setSelected(_ selected: Bool, animated: Bool) {
        imageSet(media: selected ? (selectedImage ?? normalImage) : normalImage)
    }

    @MainActor private func imageSet(media: Any) {
        mediaGeneration &+= 1
        let generation = mediaGeneration
        lottieLoadTask?.cancel()
        lottieLoadTask = nil

        switch media {
        case let string as String:
            if string.lowercased().contains("json") {
                if string.isURL(), let lottieURL = URL(string: string) {
                    // English: Guard asynchronous Lottie results with the current media generation.
                    // Español: Protege los resultados asíncronos de Lottie con la generación multimedia actual.
                    // 中文：使用当前媒体 generation 校验异步 Lottie 结果，避免回写旧图标。
                    lottieLoadTask = Task { @MainActor [weak self] in
                        let lottieAnimation = await LottieAnimation.loadedFrom(url: lottieURL)
                        guard !Task.isCancelled,
                              let self,
                              self.mediaGeneration == generation else { return }
                        self.lottieLoadTask = nil
                        if let findAnimation = lottieAnimation {
                            self.lottieAnimationSet(findAnimation: findAnimation)
                        } else {
                            self.displayRasterImage(media: self.normalImage)
                        }
                    }
                } else {
                    displayRasterImage(media: media)
                }
            } else if let findAnimation = LottieAnimation.named(string) {
                lottieAnimationSet(findAnimation: findAnimation)
            } else {
                displayRasterImage(media: media)
            }
        case let animation as LottieAnimation:
            lottieAnimationSet(findAnimation: animation)
        default:
            displayRasterImage(media: media)
        }
    }

    // English: Render non-Lottie media through the existing image-loading pipeline.
    // Español: Renderiza medios que no son Lottie mediante el pipeline de imágenes existente.
    // 中文：非 Lottie 媒体继续复用现有图片加载管线。
    private func displayRasterImage(media: Any) {
        imageView.isHidden = false
        lottieView.isHidden = true
        imageView.loadImage(contentData: media,
                            radius: appearance.layout.tabbarRadius,
                            topLeft: appearance.layout.tabbarTopLeft,
                            topRight: appearance.layout.tabbarTopRight,
                            bottomLeft: appearance.layout.tabbarBottomLeft,
                            bottomRight: appearance.layout.tabbarBottomRight,
                            corner: appearance.layout.tabbarCorner,
                            capsule: appearance.layout.tabbarCapsule,
                            borderWidth: appearance.layout.tabbarBorderWidth,
                            borderColor: appearance.layout.tabbarBorderColor,
                            showValueLabel: appearance.layout.tabbarShowValueLabel,
                            valueLabelFont: appearance.layout.loadImageShowValueFont,
                            valueLabelColor: appearance.layout.tabbarValueLabelColor)
    }

    private func lottieAnimationSet(findAnimation: LottieAnimation) {
        lottieView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        lottieView.isHidden = false
        lottieView.animation = findAnimation
        updateLottieMotionState()
    }

    // English: Keeps Lottie still when Reduce Motion is enabled and resumes it when allowed.
    // Español: Mantiene Lottie quieto cuando se reduce el movimiento y lo reanuda cuando se permite.
    // 中文：开启“减弱动态效果”时停止 Lottie，允许动态效果时恢复播放。
    private func updateLottieMotionState() {
        guard lottieView.animation != nil else { return }
        if UIAccessibility.isReduceMotionEnabled || lottieView.isHidden {
            lottieView.stop()
        } else {
            lottieView.play()
        }
    }

    @objc private func reduceMotionStatusDidChange() {
        updateLottieMotionState()
    }

    deinit {
        lottieLoadTask?.cancel()
        NotificationCenter.default.removeObserver(self,
                                                   name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                                   object: nil)
    }
}
