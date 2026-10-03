//
//  PTNestedScrollCoordinator.swift
//
// English: Own nested scrolling and offset ownership outside the paging facade.
// Español: Posee el scroll anidado y la propiedad de offsets fuera de la fachada de paginación.
// 中文：将嵌套滚动和偏移所有权从分页门面中独立出来。
//

import UIKit

/// English: Main-actor nested scroll coordinator with deterministic offset normalization.
/// Español: Coordinador de scroll anidado en MainActor con normalización determinista de offsets.
/// 中文：在 MainActor 上运行、具备确定性偏移归一化的嵌套滚动协调器。
@MainActor
open class PTNestedScrollCoordinator {
    public private(set) var ownership: PTScrollOwnership = .outer
    public private(set) var isTransferringMomentum = false
    public var collapseLimit: CGFloat = 0
    public var onCollapseProgress: ((CGFloat) -> Void)?

    public weak var outerScrollView: UIScrollView?
    public weak var innerScrollView: UIScrollView?
    public var activePageID: AnyHashable?

    private var isApplyingCorrection = false
    private var innerProxy: PTScrollDelegateProxy?

    public init() {}

    public func bind(outer: UIScrollView,
                     inner: UIScrollView?,
                     pageID: AnyHashable? = nil,
                     collapseLimit: CGFloat) {
        innerProxy?.detach()
        outerScrollView = outer
        innerScrollView = inner
        activePageID = pageID
        self.collapseLimit = max(0, collapseLimit)
        ownership = .outer
        if let inner {
            let proxy = PTScrollDelegateProxy(scrollView: inner, original: inner.delegate)
            proxy.onDidScroll = { [weak self] scrollView in
                self?.handleInnerScroll(scrollView)
            }
            proxy.onDidEndDragging = { [weak self] _, decelerate in
                if !decelerate { self?.settle() }
            }
            proxy.onDidEndDecelerating = { [weak self] _ in
                self?.settle()
            }
            inner.delegate = proxy
            innerProxy = proxy
        }
        normalize()
    }

    public func handleOuterScroll(_ scrollView: UIScrollView) {
        guard !isApplyingCorrection else { return }
        let topInset = scrollView.adjustedContentInset.top
        let y = max(0, scrollView.contentOffset.y + topInset)
        let progress = collapseLimit == 0 ? 1 : min(1, y / collapseLimit)
        onCollapseProgress?(progress)
        if let innerScrollView,
           innerScrollView.contentOffset.y + innerScrollView.adjustedContentInset.top > 0,
           y < collapseLimit {
            isApplyingCorrection = true
            scrollView.contentOffset.y = collapseLimit - topInset
            isApplyingCorrection = false
            ownership = .inner(pageID: activePageID ?? AnyHashable(""))
        } else if y < collapseLimit {
            ownership = .outer
        }
        normalize()
    }

    public func handleInnerScroll(_ scrollView: UIScrollView) {
        guard !isApplyingCorrection else { return }
        let y = max(0, scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        if y > 0 {
            ownership = .inner(pageID: activePageID ?? AnyHashable(""))
            if let outerScrollView,
               outerScrollView.contentOffset.y + outerScrollView.adjustedContentInset.top < collapseLimit {
                isApplyingCorrection = true
                outerScrollView.contentOffset.y = collapseLimit - outerScrollView.adjustedContentInset.top
                scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
                isApplyingCorrection = false
            }
        } else if let outerScrollView,
                  outerScrollView.contentOffset.y + outerScrollView.adjustedContentInset.top > 0 {
            ownership = .transitioning
            isApplyingCorrection = true
            let outerTopInset = outerScrollView.adjustedContentInset.top
            let outerY = max(0, outerScrollView.contentOffset.y + outerTopInset)
            let nextY = max(0, outerY - abs(scrollView.panGestureRecognizer.velocity(in: scrollView).y) * 0.001)
            outerScrollView.contentOffset.y = nextY - outerTopInset
            isApplyingCorrection = false
            isTransferringMomentum = true
        } else {
            ownership = .outer
        }
        normalize()
    }

    public func settle() {
        isTransferringMomentum = false
        ownership = .outer
        normalize()
    }

    private func normalize() {
        guard let outerScrollView else { return }
        let topInset = outerScrollView.adjustedContentInset.top
        let currentY = outerScrollView.contentOffset.y + topInset
        let y = min(max(0, currentY), collapseLimit)
        let normalizedOffset = y - topInset
        if abs(outerScrollView.contentOffset.y - normalizedOffset) > 0.5, !isApplyingCorrection {
            isApplyingCorrection = true
            outerScrollView.contentOffset.y = normalizedOffset
            isApplyingCorrection = false
        }
        let progress = collapseLimit == 0 ? 1 : min(1, y / collapseLimit)
        onCollapseProgress?(progress)
    }
}
