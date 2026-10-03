//
//  PTScrollDelegateProxy.swift
//
// English: Multiplex UIScrollView callbacks without taking ownership away from the paging coordinator.
// Español: Multiplexa callbacks de UIScrollView sin quitar la propiedad al coordinador de paginación.
// 中文：复用 UIScrollView 回调，同时不改变分页协调器的所有权。
//

import UIKit

@MainActor
final class PTScrollDelegateProxy: NSObject, UIScrollViewDelegate {
    weak var scrollView: UIScrollView?
    weak var original: UIScrollViewDelegate?
    var onDidScroll: ((UIScrollView) -> Void)?
    var onDidEndDragging: ((UIScrollView, Bool) -> Void)?
    var onDidEndDecelerating: ((UIScrollView) -> Void)?

    init(scrollView: UIScrollView, original: UIScrollViewDelegate?) {
        self.scrollView = scrollView
        self.original = original
    }

    func detach() {
        if scrollView?.delegate === self {
            scrollView?.delegate = original
        }
        onDidScroll = nil
        onDidEndDragging = nil
        onDidEndDecelerating = nil
        scrollView = nil
        original = nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onDidScroll?(scrollView)
        original?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        original?.scrollViewWillBeginDragging?(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        onDidEndDragging?(scrollView, decelerate)
        original?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        original?.scrollViewWillEndDragging?(scrollView,
                                              withVelocity: velocity,
                                              targetContentOffset: targetContentOffset)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        original?.scrollViewWillBeginDecelerating?(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onDidEndDecelerating?(scrollView)
        original?.scrollViewDidEndDecelerating?(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        original?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        original?.viewForZooming?(in: scrollView)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        original?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView,
                                 with view: UIView?,
                                 atScale scale: CGFloat) {
        original?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        original?.scrollViewDidZoom?(scrollView)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        original?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        original?.scrollViewDidScrollToTop?(scrollView)
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        original?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}
