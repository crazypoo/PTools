//
//  PTTabBarMediaContent.swift
//  PooTools
//
//  English: Tab-bar media rendering is isolated from the tab-bar container.
//  Español: La representación multimedia de la barra de pestañas está aislada del contenedor.
//  中文：将标签栏媒体渲染职责从标签栏容器中独立出来。
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
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
        imageView.ptLayout.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        lottieView.isHidden = true
        lottieView.loopMode = .autoReverse
        lottieView.ptLayout.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reduceMotionStatusDidChange),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil)
    }

    public var view: UIView { container }

    // English: Resolve only local raster assets; remote URLs and Lottie remain in the custom renderer.
    // Español: Resuelve solo recursos rasterizados locales; las URL remotas y Lottie permanecen en el renderizador personalizado.
    // 中文：这里只解析本地位图资源；远程 URL 和 Lottie 继续由自定义渲染器处理。
    public var systemImage: UIImage? {
        resolveSystemImage(normalImage)
    }

    public var systemSelectedImage: UIImage? {
        guard let selectedImage else { return nil }
        return resolveSystemImage(selectedImage)
    }

    @MainActor public func setSelected(_ selected: Bool, animated: Bool) {
        imageSet(media: selected ? (selectedImage ?? normalImage) : normalImage)
    }

    // English: Native UIKit bars may tint automatic raster images; preserve ordinary assets while keeping explicit symbol modes.
    // Español: Las barras nativas de UIKit pueden teñir imágenes rasterizadas automáticas; conserva los recursos normales y respeta los modos explícitos de los símbolos.
    // 中文：UIKit 原生 Bar 可能会给 automatic 位图重新着色；保留普通资源原色，同时保留符号的显式渲染模式。
    private func resolveSystemImage(_ media: Any) -> UIImage? {
        if let image = media as? UIImage {
            return normalizedSystemBarImage(image)
        }
        guard let name = media as? String, !name.isEmpty else { return nil }
        if let namedImage = UIImage(named: name) {
            return normalizedSystemBarImage(namedImage)
        }
        // English: SF Symbols remain template images so the system bar can apply its selected-state tint.
        // Español: Los SF Symbols siguen siendo imágenes de plantilla para que la barra aplique el tinte del estado seleccionado.
        // 中文：SF Symbols 保持模板图片，让系统 Bar 继续应用选中态颜色。
        return UIImage(systemName: name)
    }

    // English: Only automatic images are converted; caller-selected template/original rendering remains authoritative.
    // Español: Solo se convierten las imágenes automáticas; el modo de plantilla/original elegido por el llamador sigue siendo prioritario.
    // 中文：只转换 automatic 图片；调用方明确指定的 template/original 渲染模式保持不变。
    private func normalizedSystemBarImage(_ image: UIImage) -> UIImage {
        switch image.renderingMode {
        case .automatic:
            return image.withRenderingMode(.alwaysOriginal)
        case .alwaysOriginal, .alwaysTemplate:
            return image
        @unknown default:
            return image.withRenderingMode(.alwaysOriginal)
        }
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
