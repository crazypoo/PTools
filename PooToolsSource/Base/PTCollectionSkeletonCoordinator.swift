//
//  PTCollectionSkeletonCoordinator.swift
//  PooTools
//
// English: Keep skeleton presentation and geometry separate from Diffable data updates.
// Español: Mantiene la presentación y la geometría del skeleton separadas de las actualizaciones Diffable.
// 中文：将骨架展示和几何布局与 Diffable 数据更新分离。
//

import UIKit

extension PTCollectionView {
    /// 显示独立的骨架覆盖层，不改变当前 Diffable snapshot。
    public func showSkeleton(itemCount: Int? = nil) {
        showSkeleton(itemCount: itemCount,
                     configuration: viewConfig.skeletonConfiguration ?? PTCollectionSkeletonConfiguration())
    }

    /// 显示带独立几何、内容、动画和状态策略的骨架覆盖层。
    public func showSkeleton(itemCount: Int? = nil,
                             configuration: PTCollectionSkeletonConfiguration) {
        skeletonShowTask?.cancel()
        skeletonMinimumVisibleTask?.cancel()
        activeSkeletonConfiguration = configuration
        activeSkeletonItemCount = itemCount.map { min(max($0, 1), 50) }
        let token = presentationCoordinator.beginSkeleton()
        explicitLoadingRequested = false
        skeletonIsPending = configuration.showDelay > 0
        if !skeletonIsPending {
            PTUnavailableManager.hideUnavailableView(in: self)
        }

        let show = { @MainActor [weak self] in
            guard let self, self.presentationCoordinator.isCurrent(token), self.presentationCoordinator.skeletonRequested else { return }
            self.skeletonIsPending = false
            self.isSkeletonVisible = true
            self.collectionView.isSkeletonPresentationSuppressed = true
            PTUnavailableManager.hideUnavailableView(in: self)
            self.skeletonVisibleSince = ContinuousClock.now
            // English: Hide real cells while keeping the skeleton layer's original visual contrast.
            // Español: Oculta las celdas reales y conserva el contraste visual original de la capa skeleton.
            // 中文：隐藏真实 Cell，同时保留骨架层原有的视觉对比度。
            if self.skeletonUnderlyingCollectionAlpha == nil {
                self.skeletonUnderlyingCollectionAlpha = self.collectionView.alpha
            }
            self.collectionView.alpha = 0
            self.skeletonOverlayView.isHidden = false
            self.skeletonOverlayView.alpha = 1
            self.skeletonOverlayView.isUserInteractionEnabled = configuration.interactionPolicy != .passthrough
            self.bringSubviewToFront(self.skeletonOverlayView)
            self.updateSkeletonLayout()
            self.skeletonOverlayView.startAnimation(configuration.animation)
        }

        guard configuration.showDelay > 0 else {
            show()
            return
        }
        skeletonShowTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(configuration.showDelay))
                guard !Task.isCancelled else { return }
                show()
            } catch {
                // English: Cancellation is the expected path when a fast request finishes before the delay.
                // Español: La cancelación es el camino esperado cuando una solicitud rápida termina antes del retraso.
                // 中文：快速请求在延迟结束前完成时，取消任务是预期路径。
            }
            self?.skeletonShowTask = nil
        }
    }

    /// 隐藏骨架覆盖层，并按最新已提交 Snapshot 恢复 Empty 或 Content。
    public func hideSkeleton() {
        skeletonShowTask?.cancel()
        skeletonShowTask = nil
        let configuration = activeSkeletonConfiguration
        let token = presentationCoordinator.endSkeleton()

        guard isSkeletonVisible || !skeletonOverlayView.isHidden || configuration != nil else {
            reconcilePresentation()
            return
        }

        let elapsed: TimeInterval
        if let skeletonVisibleSince {
            let components = skeletonVisibleSince.duration(to: .now).components
            elapsed = Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
        } else {
            elapsed = 0
        }
        let remaining = max(0, (configuration?.minimumVisibleDuration ?? 0) - elapsed)
        guard remaining > 0 else {
            finishSkeletonHide(token: token, configuration: configuration)
            return
        }

        skeletonMinimumVisibleTask?.cancel()
        skeletonMinimumVisibleTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(remaining))
                guard !Task.isCancelled else { return }
                self?.finishSkeletonHide(token: token, configuration: configuration)
            } catch {
                // English: A newer show/hide generation owns the overlay after cancellation.
                // Español: Una generación nueva de show/hide posee el overlay después de la cancelación.
                // 中文：取消后由更新的 show/hide generation 继续拥有覆盖层。
            }
        }
    }

    public func updateSkeleton(configuration: PTCollectionSkeletonConfiguration,
                               animated: Bool = true) {
        activeSkeletonConfiguration = configuration
        if isSkeletonVisible {
            let update = { @MainActor [weak self] in
                guard let self else { return }
                if animated, configuration.transition.duration > 0 {
                    UIView.animate(withDuration: configuration.transition.duration) {
                        self.updateSkeletonLayout()
                    }
                } else {
                    self.updateSkeletonLayout()
                }
                self.skeletonOverlayView.startAnimation(configuration.animation)
            }
            update()
        }
    }

    public func invalidateSkeletonLayout() {
        updateSkeletonLayout()
    }

    private func finishSkeletonHide(token: UInt64,
                                    configuration: PTCollectionSkeletonConfiguration?) {
        guard !presentationCoordinator.skeletonRequested || presentationCoordinator.isCurrent(token) else { return }
        isSkeletonVisible = false
        skeletonIsPending = false
        activeSkeletonItemCount = nil
        activeSkeletonConfiguration = nil
        skeletonVisibleSince = nil
        skeletonMinimumVisibleTask = nil
        let duration = configuration?.transition.duration ?? 0
        let hide = { @MainActor [weak self] in
            guard let self else { return }
            guard !self.presentationCoordinator.skeletonRequested || self.presentationCoordinator.isCurrent(token) else { return }
            self.skeletonOverlayView.stopShimmer()
            self.skeletonOverlayView.isHidden = true
            self.skeletonOverlayView.alpha = 1
            // English: Restore the caller's collection alpha after the skeleton is fully hidden.
            // Español: Restaura el alpha de la colección después de ocultar por completo el skeleton.
            // 中文：骨架完全隐藏后恢复调用方原先设置的 Collection alpha。
            self.collectionView.alpha = self.skeletonUnderlyingCollectionAlpha ?? 1
            self.skeletonUnderlyingCollectionAlpha = nil
            self.reconcilePresentation()
        }
        if duration > 0, !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: duration, animations: { [weak self] in
                self?.skeletonOverlayView.alpha = 0
            }, completion: { _ in hide() })
        } else {
            hide()
        }
    }
}

extension PTCollectionView {
    func updateSkeletonLayout() {
        guard isSkeletonVisible else { return }
        bringSubviewToFront(skeletonOverlayView)
        let configuration = activeSkeletonConfiguration ?? PTCollectionSkeletonConfiguration()
        let direction = effectiveUserInterfaceLayoutDirection
        let items = PTCollectionSkeletonLayoutResolver.resolve(bounds: skeletonOverlayView.bounds,
                                                                viewConfig: viewConfig,
                                                                configuration: configuration,
                                                                explicitItemCount: activeSkeletonItemCount,
                                                                adjustedContentInset: collectionView.adjustedContentInset,
                                                                layoutDirection: direction)
        skeletonOverlayView.render(items: items,
                                   appearance: PTSkeletonThemeDefaults.appearance ?? configuration.appearance,
                                   animation: configuration.animation,
                                   accessibilityLabel: configuration.accessibilityLabel)
    }
}

//MARK: Get something
extension PTCollectionView {
#if POOTOOLS_PAGINGCONTROL
    public func segmentScrolView() -> UIScrollView {
        collectionView
    }
#endif
    
    public func visibleCells() -> [UICollectionViewCell] {
        collectionView.visibleCells
    }
}

//MARK: MoveItem
extension PTCollectionView {
    public func scrolToItem(indexPath:IndexPath,position:UICollectionView.ScrollPosition) {
        collectionView.scrollToItem(at: indexPath,
                                    at: position,
                                    animated: !PTUIAccessibility.reduceMotionEnabled)
    }
    
    public func mtSelectItem(indexPath:IndexPath,animated:Bool,scrollPosition:UICollectionView.ScrollPosition) {
        collectionView.selectItem(at: indexPath,
                                  animated: animated && !PTUIAccessibility.reduceMotionEnabled,
                                  scrollPosition: scrollPosition)
    }
}
