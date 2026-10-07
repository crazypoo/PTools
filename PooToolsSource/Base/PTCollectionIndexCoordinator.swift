//
//  PTCollectionIndexCoordinator.swift
//  PooTools
//
// English: Keep side-index construction and gestures outside the collection facade.
// Español: Mantiene la construcción y los gestos del índice lateral fuera de la fachada de colección.
// 中文：将侧边索引构建和手势逻辑从 CollectionView 门面中拆出。
//

import UIKit
import SnapKit

//MARK: 索引设置
extension PTCollectionView {
    func setIndexViews() {
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
        
        indexContainerView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(viewConfig.indexConfig?.indexContainerRightOffset ?? 0)
            make.top.equalToSuperview().inset(viewConfig.indexConfig?.containerTopOffset ?? 0)
            make.bottom.equalToSuperview().inset(viewConfig.indexConfig?.containerBottomOffset ?? 0)
            make.width.equalTo(viewConfig.indexConfig?.itemSize.width ?? 20)
        }
        
        setupIndexUI()
        addIndexGesture()
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
                let indicatorX = bounds.width - indicator.bounds.width / 2 - (config.itemSize.width)
                
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
        
        stackView.snp.makeConstraints { make in
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
            label.snp.makeConstraints { make in
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
