//
//  PTCollectionViewSkeleton.swift
//  PooTools
//
// English: Keep skeleton rendering independent from the collection facade.
// Español: Mantiene el renderizado del skeleton independiente de la fachada de colección.
// 中文：将骨架渲染从 CollectionView 门面中独立出来。
//

import UIKit

// 写在文件顶部或合适的扩展中
public typealias PTDataSource = UICollectionViewDiffableDataSource<PTSection, PTRows>
public typealias PTSnapshot = NSDiffableDataSourceSnapshot<PTSection, PTRows>

@MainActor
final class PTSkeletonOverlayView: UIView {
    private static let animationKey = "PTCollectionView.skeletonShimmer"

    private struct LayoutSignature: Equatable {
        let rects: [CGRect]
        let cornerRadius: CGFloat
    }

    private let baseLayer = CAShapeLayer()
    private let shimmerLayer = CAGradientLayer()
    private let shimmerMask = CAShapeLayer()
    private var layoutSignature: LayoutSignature?
    private var wantsShimmer = false

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
        let signature = LayoutSignature(rects: rects, cornerRadius: radius)
        guard signature != layoutSignature else { return }
        layoutSignature = signature

        let path = UIBezierPath()
        for rect in rects {
            path.append(UIBezierPath(roundedRect: rect, cornerRadius: radius))
        }
        baseLayer.path = path.cgPath
        shimmerMask.path = path.cgPath
    }

    func startShimmerIfNeeded() {
        wantsShimmer = true
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
        shimmerLayer.isHidden = reduceMotionEnabled
        guard wantsShimmer, window != nil, !isHidden, !reduceMotionEnabled else {
            shimmerLayer.removeAnimation(forKey: Self.animationKey)
            return
        }

        guard shimmerLayer.animation(forKey: Self.animationKey) == nil else { return }

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.2
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmerLayer.add(animation, forKey: Self.animationKey)
    }

    private func updateColors() {
        let baseColor = UIColor.secondarySystemBackground.resolvedColor(with: traitCollection)
        let highlightColor = UIColor.tertiarySystemBackground.resolvedColor(with: traitCollection)
        baseLayer.fillColor = baseColor.cgColor
        shimmerLayer.colors = [baseColor.cgColor, highlightColor.cgColor, baseColor.cgColor]
        shimmerLayer.locations = [0, 0.5, 1]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }
}
