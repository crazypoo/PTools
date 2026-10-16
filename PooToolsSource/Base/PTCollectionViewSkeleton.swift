//
//  PTCollectionViewSkeleton.swift
//  PooTools
//
// English: Keep skeleton rendering independent from the collection facade.
// Español: Mantiene el renderizado del skeleton independiente de la fachada de colección.
// 中文：将骨架渲染从 CollectionView 门面中独立出来。
//

import UIKit

// English: Keep the legacy aliases source-compatible while PTCollectionView uses identity-only Diffable state internally.
// Español: Conserva los alias heredados compatibles mientras PTCollectionView usa internamente un Diffable basado solo en identidades.
// 中文：保留旧别名的源码兼容性，同时让 PTCollectionView 内部的 Diffable 只保存稳定身份。
public typealias PTDataSource = UICollectionViewDiffableDataSource<PTSection, PTRows>
public typealias PTSnapshot = NSDiffableDataSourceSnapshot<PTSection, PTRows>

// English: Snapshot identifiers carry order and identity; mutable section and row content lives in PTCollectionModelStore.
// Español: Los identificadores transportan orden e identidad; el contenido mutable vive en PTCollectionModelStore.
// 中文：快照只承载顺序和身份，可变 Section/Row 内容由 PTCollectionModelStore 保存。
public typealias PTCollectionIDDataSource = UICollectionViewDiffableDataSource<PTSectionIdentifier, PTRowIdentifier>
public typealias PTCollectionIDSnapshot = NSDiffableDataSourceSnapshot<PTSectionIdentifier, PTRowIdentifier>

// English: Adapt legacy model arguments to the identity-only snapshot without changing callers.
// Español: Adapta argumentos de modelos heredados al snapshot basado solo en identidades sin cambiar a los consumidores.
// 中文：将旧模型参数适配到纯身份快照，不改变现有调用方。
public extension NSDiffableDataSourceSnapshot where SectionIdentifierType == PTSectionIdentifier, ItemIdentifierType == PTRowIdentifier {
    mutating func appendSections(_ sections: [PTSection]) {
        appendSections(sections.map { PTSectionIdentifier($0.identifier) })
    }

    mutating func insertSections(_ sections: [PTSection], afterSection section: PTSectionIdentifier) {
        insertSections(sections.map { PTSectionIdentifier($0.identifier) }, afterSection: section)
    }

    mutating func appendItems(_ rows: [PTRows], toSection section: PTSection) {
        appendItems(rows.map { PTRowIdentifier($0.diffId) }, toSection: PTSectionIdentifier(section.identifier))
    }

    mutating func appendItems(_ rows: [PTRows], toSection section: PTSectionIdentifier) {
        appendItems(rows.map { PTRowIdentifier($0.diffId) }, toSection: section)
    }

    mutating func insertItems(_ rows: [PTRows], beforeItem item: PTRowIdentifier) {
        insertItems(rows.map { PTRowIdentifier($0.diffId) }, beforeItem: item)
    }

    mutating func reloadItems(_ rows: [PTRows]) {
        reloadItems(rows.map { PTRowIdentifier($0.diffId) })
    }

    mutating func reconfigureItems(_ rows: [PTRows]) {
        reconfigureItems(rows.map { PTRowIdentifier($0.diffId) })
    }

    mutating func deleteItems(_ rows: [PTRows]) {
        deleteItems(rows.map { PTRowIdentifier($0.diffId) })
    }

    mutating func reloadSections(_ sections: [PTSection]) {
        reloadSections(sections.map { PTSectionIdentifier($0.identifier) })
    }

    mutating func deleteSections(_ sections: [PTSection]) {
        deleteSections(sections.map { PTSectionIdentifier($0.identifier) })
    }

    func indexOfSection(_ section: PTSection) -> Int? {
        indexOfSection(PTSectionIdentifier(section.identifier))
    }
}

@MainActor
final class PTSkeletonOverlayView: UIView {
    private static let animationKey = "PTCollectionView.skeletonShimmer"
    private static let pulseKey = "PTCollectionView.skeletonPulse"

    private struct LayoutSignature: Equatable {
        let rects: [CGRect]
        let cornerRadius: CGFloat
        let descriptors: String
    }

    private let baseLayer = CAShapeLayer()
    private let shimmerLayer = CAGradientLayer()
    private let shimmerMask = CAShapeLayer()
    private var layoutSignature: LayoutSignature?
    private var wantsShimmer = false
    private var animationConfiguration = PTCollectionSkeletonAnimation.legacyShimmer
    private var appearanceConfiguration = PTCollectionSkeletonAppearance()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        clipsToBounds = true
        backgroundColor = .clear

        shimmerLayer.mask = shimmerMask
        layer.addSublayer(baseLayer)
        layer.addSublayer(shimmerLayer)
        updateColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: PTSkeletonOverlayView, _) in
            view.updateColors()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusDidChange),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        baseLayer.frame = bounds
        shimmerLayer.frame = bounds
        shimmerMask.frame = bounds
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateShimmerState()
    }

    func update(rects: [CGRect], cornerRadius: CGFloat) {
        let radius = max(0, cornerRadius)
        let signature = LayoutSignature(rects: rects, cornerRadius: radius, descriptors: "legacy")
        guard signature != layoutSignature else { return }
        layoutSignature = signature

        let path = UIBezierPath()
        for rect in rects {
            path.append(UIBezierPath(roundedRect: rect, cornerRadius: radius))
        }
        baseLayer.path = path.cgPath
        shimmerMask.path = path.cgPath
    }

    func render(items: [PTSkeletonRenderedItem],
                appearance: PTCollectionSkeletonAppearance,
                animation: PTCollectionSkeletonAnimation,
                accessibilityLabel: String?) {
        appearanceConfiguration = appearance
        animationConfiguration = animation
        self.accessibilityLabel = accessibilityLabel

        let path = UIBezierPath()
        for item in items.prefix(200) {
            appendShapes(item.descriptor.shapes,
                         in: item.frame,
                         to: path,
                         fallbackCornerRadius: 8)
        }
        let rects = items.map(\.frame)
        let descriptors = items.prefix(200).map { String(describing: $0.descriptor) }.joined(separator: "|")
        let signature = LayoutSignature(rects: rects, cornerRadius: 0, descriptors: descriptors)
        if signature != layoutSignature || baseLayer.path == nil {
            layoutSignature = signature
            baseLayer.path = path.cgPath
            shimmerMask.path = path.cgPath
        }
        updateColors()
        wantsShimmer = animation.style != .none && animation.style != .solid && animation.style != .gradient
        updateShimmerState()
    }

    func startShimmerIfNeeded() {
        wantsShimmer = true
        animationConfiguration = .legacyShimmer
        updateShimmerState()
    }

    func startAnimation(_ animation: PTCollectionSkeletonAnimation) {
        animationConfiguration = animation
        wantsShimmer = animation.style != .none && animation.style != .solid && animation.style != .gradient
        updateShimmerState()
    }

    func stopShimmer() {
        wantsShimmer = false
        updateShimmerState()
    }

    @objc private func reduceMotionStatusDidChange() {
        updateShimmerState()
    }

    private func updateShimmerState() {
        let reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        shimmerLayer.isHidden = reduceMotionEnabled || animationConfiguration.style == .solid || animationConfiguration.style == .none
        baseLayer.isHidden = false
        baseLayer.opacity = animationConfiguration.style == .pulse ? appearanceConfiguration.pulseMaximumAlpha : 1
        shimmerLayer.removeAnimation(forKey: Self.animationKey)
        baseLayer.removeAnimation(forKey: Self.pulseKey)
        guard wantsShimmer, window != nil, !isHidden, !reduceMotionEnabled else {
            shimmerLayer.removeAnimation(forKey: Self.animationKey)
            return
        }

        switch animationConfiguration.style {
        case .pulse:
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = appearanceConfiguration.pulseMinimumAlpha
            animation.toValue = appearanceConfiguration.pulseMaximumAlpha
            animation.duration = animationConfiguration.duration
            animation.autoreverses = animationConfiguration.autoreverses
            animation.repeatCount = animationConfiguration.repeatCount
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            baseLayer.add(animation, forKey: Self.pulseKey)
        case .shimmer:
            let animation = CABasicAnimation(keyPath: "locations")
            animation.fromValue = [-1, -0.5, 0]
            animation.toValue = [1, 1.5, 2]
            animation.duration = animationConfiguration.duration
            animation.autoreverses = animationConfiguration.autoreverses
            animation.repeatCount = animationConfiguration.repeatCount
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            shimmerLayer.add(animation, forKey: Self.animationKey)
        case .solid, .gradient, .none:
            break
        }
    }

    private func updateColors() {
        let baseColor = appearanceConfiguration.baseColor.resolvedColor(with: traitCollection)
        baseLayer.fillColor = baseColor.cgColor
        let colors = (appearanceConfiguration.gradientColors ?? [appearanceConfiguration.baseColor,
                                                                  appearanceConfiguration.highlightColor,
                                                                  appearanceConfiguration.baseColor])
            .map { $0.resolvedColor(with: traitCollection).cgColor }
        shimmerLayer.colors = colors
        shimmerLayer.locations = colors.count == 3 ? [0, 0.5, 1] : nil
        // English: Map every public direction to one gradient vector so the animation configuration is visible.
        // Español: Mapea cada dirección pública a un vector de gradiente para que la configuración sea visible.
        // 中文：将每个公开方向映射到渐变向量，确保动画配置真实生效。
        switch animationConfiguration.direction {
        case .leftToRight:
            shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
            shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        case .rightToLeft:
            shimmerLayer.startPoint = CGPoint(x: 1, y: 0.5)
            shimmerLayer.endPoint = CGPoint(x: 0, y: 0.5)
        case .topToBottom:
            shimmerLayer.startPoint = CGPoint(x: 0.5, y: 0)
            shimmerLayer.endPoint = CGPoint(x: 0.5, y: 1)
        case .bottomToTop:
            shimmerLayer.startPoint = CGPoint(x: 0.5, y: 1)
            shimmerLayer.endPoint = CGPoint(x: 0.5, y: 0)
        case .topLeadingToBottomTrailing:
            shimmerLayer.startPoint = CGPoint(x: 0, y: 0)
            shimmerLayer.endPoint = CGPoint(x: 1, y: 1)
        case .bottomTrailingToTopLeading:
            shimmerLayer.startPoint = CGPoint(x: 1, y: 1)
            shimmerLayer.endPoint = CGPoint(x: 0, y: 0)
        }
    }

    private func appendShapes(_ shapes: [PTSkeletonShape],
                              in itemFrame: CGRect,
                              to path: UIBezierPath,
                              fallbackCornerRadius: CGFloat) {
        let safeShapes = shapes.isEmpty ? [PTSkeletonShape.roundedRect(CGRect(x: 0, y: 0, width: 1, height: 1), cornerRadius: fallbackCornerRadius)] : shapes
        for shape in safeShapes.prefix(40) {
            let frame: CGRect
            if shape.isNormalized {
                frame = CGRect(x: itemFrame.minX + shape.localFrame.minX * itemFrame.width,
                               y: itemFrame.minY + shape.localFrame.minY * itemFrame.height,
                               width: shape.localFrame.width * itemFrame.width,
                               height: shape.localFrame.height * itemFrame.height)
            } else {
                frame = CGRect(x: itemFrame.minX + shape.localFrame.minX,
                               y: itemFrame.minY + shape.localFrame.minY,
                               width: shape.localFrame.width,
                               height: shape.localFrame.height)
            }
            guard frame.width > 0, frame.height > 0,
                  frame.minX.isFinite, frame.minY.isFinite,
                  frame.width.isFinite, frame.height.isFinite else { continue }
            switch shape.kind {
            case .circle:
                // English: A circle must stay circular even when its item frame is rectangular.
                // Español: Un círculo debe seguir siendo circular aunque el marco del ítem sea rectangular.
                // 中文：即使 Item 容器是矩形，圆形也必须保持真正的圆。
                let diameter = min(frame.width, frame.height)
                let circleFrame = CGRect(x: frame.midX - diameter / 2,
                                         y: frame.midY - diameter / 2,
                                         width: diameter,
                                         height: diameter)
                path.append(UIBezierPath(ovalIn: circleFrame))
            case .line, .roundedRect:
                path.append(UIBezierPath(roundedRect: frame, cornerRadius: min(shape.cornerRadius, min(frame.width, frame.height) / 2)))
            case .rect:
                path.append(UIBezierPath(rect: frame))
            }
        }
    }
}
