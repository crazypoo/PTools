//
//  PTCollectionIndexCoordinator.swift
//  PooTools
//
// English: Keep side-index construction and gestures outside the collection facade.
// Español: Mantiene la construcción y los gestos del índice lateral fuera de la fachada de colección.
// 中文：将侧边索引构建和手势逻辑从 CollectionView 门面中拆出。
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import SnapKit

//MARK: 索引设置
extension PTCollectionView {
    func setIndexViews() {
        indexLayoutSignature = nil
        if let indexPanGesture {
            indexContainerView.removeGestureRecognizer(indexPanGesture)
            self.indexPanGesture = nil
        }
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        indicator.removeFromSuperview()
        indexContainerView.removeFromSuperview()
        guard viewConfig.sideIndexTitles?.isEmpty == false,
              viewConfig.indexConfig != nil else { return }
        
        addSubviews([indexContainerView,indicator])
        
        setupIndexUI()
        addIndexGesture()
        updateIndexPlacementIfNeeded()
    }

    // English: Keep the side index inside the host's safe visible region.
    // Español: Mantiene el índice lateral dentro de la región visible segura del host.
    // 中文：将侧边索引限制在宿主的安全可视区域内。
    func updateIndexPlacementIfNeeded() {
        // English: Do not create constraints until the index view is attached to this host.
        // Español: No crees restricciones hasta que la vista del índice esté unida a este host.
        // 中文：侧边索引加入当前宿主前，不创建任何约束。
        guard viewConfig.sideIndexTitles?.isEmpty == false,
              let config = viewConfig.indexConfig,
              indexContainerView.superview === self,
              !indexContainerView.isHidden,
              bounds.width > 0,
              bounds.height > 0 else { return }

        let region = PTAdaptiveVisibleRegionResolver.region(for: self)
        let signature = "\(region.signature)|\(config.itemSize)|\(config.containerTopOffset)|\(config.containerBottomOffset)|\(config.indexContainerRightOffset)"
        guard signature != indexLayoutSignature else { return }
        indexLayoutSignature = signature

        let visible = region.visibleRect
        indexContainerView.ptLayout.remakeConstraints { make in
            make.right.equalToSuperview().offset(-(bounds.width - visible.maxX + config.indexContainerRightOffset))
            make.top.equalToSuperview().offset(visible.minY + config.containerTopOffset)
            make.bottom.equalToSuperview().offset(-(bounds.height - visible.maxY + config.containerBottomOffset))
            make.width.equalTo(max(config.itemSize.width, 44))
        }
        setNeedsLayout()
    }

    private func addIndexGesture() {
        let pan = UIPanGestureRecognizer { [weak self] sender in
            guard let self = self, let gesture = sender as? UIPanGestureRecognizer else { return }
            let point = gesture.location(in: self.stackView)
            
            for case let view as PTIndexItemView in self.stackView.arrangedSubviews {
                if view.frame.contains(point) {
                    self.selectIndex(view.index)
                    break
                }
            }
            
            if gesture.state == .ended || gesture.state == .cancelled {
                self.hideIndicator()
            }
        }
        indexPanGesture = pan
        indexContainerView.addGestureRecognizer(pan)
    }
        
    private func selectIndex(_ index: Int) {
        guard let config = viewConfig.indexConfig else { return }
        
        for case let view as PTIndexItemView in stackView.arrangedSubviews {
            view.update(selected: view.index == index, config: config)
        }
        
        showIndicator(at: index)
        scrollToSection(index)
    }
    
    private func scrollToSection(_ section: Int) {
        let snapshot = diffableDataSource.snapshot()
        guard section >= 0, section < snapshot.sectionIdentifiers.count else { return }
        let sectionIdentifier = snapshot.sectionIdentifiers[section]
        let sectionModel = resolvedSection(sectionIdentifier)
        guard !snapshot.itemIdentifiers(inSection: sectionIdentifier).isEmpty,
              !(sectionModel.rows ?? []).isEmpty else {
            isTouched = false
            return
        }
        let indexPath = IndexPath(item: 0, section: section)
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        isTouched = false
    }
    
    func showIndicator(at index: Int) {
        guard let titles = viewConfig.sideIndexTitles,
              index < titles.count,
              let config = viewConfig.indexConfig else { return }
        
        bigTextLabel.text = titles[index]
        setIndicatorCenter(t: index, config: config)
    }

    func setIndicatorCenter(t index: Int,config:PTCollectionIndexViewConfiguration,alpha:CGFloat = 1) {
        for case let targetView as PTIndexItemView in stackView.arrangedSubviews {
            if targetView.index == index {
                let targetFrame = targetView.convert(targetView.bounds, to: self)
                let centerY = targetFrame.midY
                let visibleRect = PTAdaptiveVisibleRegionResolver.region(for: self).visibleRect
                let indicatorX = max(visibleRect.minX + indicator.bounds.width / 2,
                                     indexContainerView.frame.minX - indicator.bounds.width / 2)
                
                UIView.animate(withDuration: PTUIAccessibility.animationDuration(0.15)) {
                    self.indicator.center = CGPoint(x: indicatorX, y: centerY)
                }
                
                indicator.alpha = alpha
                break
            }
        }
    }
    
    private func setupIndexUI() {
        guard let titles = viewConfig.sideIndexTitles,
              let config = viewConfig.indexConfig else { return }
        
        indexContainerView.addSubview(stackView)
        
        stackView.ptLayout.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.spacing = config.itemSpacing
        
        topSpacer.backgroundColor = .clear
        bottomSpacer.backgroundColor = .clear

        topSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        bottomSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)

        topSpacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        bottomSpacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        stackView.addArrangedSubview(topSpacer)

        for (i, title) in titles.enumerated() {
            let label = PTIndexItemView()
            label.index = i
            label.text = title
            label.textAlignment = .center
            PTUIAccessibility.applyDynamicType(to: label, font: config.indexViewFont)
            label.layer.cornerRadius = config.itemSize.height / 2
            label.clipsToBounds = true
            label.isUserInteractionEnabled = true
            label.ptLayout.makeConstraints { make in
                make.size.equalTo(config.itemSize)
            }
            
            let tap = UITapGestureRecognizer { [weak self] sender in
                guard let self = self else { return }
                self.isTouched = true
                self.selectIndex(label.index)
            }
            label.addGestureRecognizer(tap)
            stackView.addArrangedSubview(label)
        }
        
        stackView.addArrangedSubview(bottomSpacer)

        setIndicatorCenter(t: 0, config: config,alpha: 0)
    }
}
