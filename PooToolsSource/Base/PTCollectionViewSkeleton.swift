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
