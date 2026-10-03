// English: Selection synchronization and animated selection-surface geometry for PTTabBarView.
// Español: Sincronización de selección y geometría animada de la superficie seleccionada.
// 中文：集中处理 PTTabBarView 的选择同步和选中表面动画几何。

import UIKit

@MainActor
extension PTTabBarView {

    /// Updates the visual selection without invoking selection callbacks.
    /// Used by PTBaseTabBarViewController when UIKit changes selectedIndex
    /// programmatically.
    @MainActor
    func synchronizeSelection(to index: Int) {
        guard index >= 0, index < items.count else { return }

        let wasMinimized = minimizedCenterView.superview != nil
        if wasMinimized, currentIndex >= 0, currentIndex < items.count {
            let previousIcon = items[currentIndex].imageContent
            items[currentIndex].addSubview(previousIcon)
            items[currentIndex].restoreIconLayout()
        }

        currentIndex = index
        for (itemIndex, item) in items.enumerated() {
            item.isSelectedItem = itemIndex == index
        }

        if wasMinimized {
            let selectedIcon = items[index].imageContent
            minimizedCenterView.addSubview(selectedIcon)
            selectedIcon.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(items[index].itemImageSize())
            }
        }
        updateSelectionMaskFrame(to: index, animated: false)
    }
    

    public func select(_ index: Int) {
        select(index, userInitiated: false)
    }

    public func select(_ index: Int, userInitiated: Bool = false) {
        guard index >= 0, index < items.count else { return }

        // 如果是重复点击
        if index == currentIndex {
            for i in items.indices {
                items[i].isSelectedItem = i == index
            }
            didSelectIndex?(index)
            didSelectInsideIndex?(index)
            if userInitiated { PTFeedbackCenter.shared.emit(.selectionChanged) }
            return
        }

        // 1️⃣ 是否允许选中
        if let should = shouldSelectIndex, should(index) == false {
            return
        }

        // 2️⃣ 即将选中
        willSelectIndex?(index)

        // 3️⃣ 更新UI
        for (i, item) in items.enumerated() {
            item.isSelectedItem = (i == index)
        }

        currentIndex = index
        // 🌟 触发底色游标的丝滑平移过渡
        updateSelectionMaskFrame(to: index, animated: true)
        // 4️⃣ 已选中
        didSelectIndex?(index)
        didSelectInsideIndex?(index)
        if userInitiated { PTFeedbackCenter.shared.emit(.selectionChanged) }
    }
    
    // 🌟 新增核心算法：追踪目标 Item 并执行 Frame 平移动画
    func updateSelectionMaskFrame(to index: Int,
                                  animated: Bool,
                                  ensuringLayout: Bool = true) {
        guard appearanceSnapshot.layout.tabSelectedMetail,
              index >= 0,
              index < items.count else { return }
        
        // 确保布局刷新完毕，拿到最真实的子视图 Frame
        if ensuringLayout {
            self.layoutIfNeeded()
        }
        
        let targetItem = items[index]
        guard let stackView = targetItem.superview else { return }
        
        // 决定计算坐标系的参考层
        let targetContainer = (glassBackgroundView.superview != nil) ? glassBackgroundView.contentView : self
        
        // 坐标系转换：把目标 Item 在 StackView 里的 frame 转换到当前参照层中
        let convertedFrame = stackView.convert(targetItem.frame, to: targetContainer)
        
        // 还原原有的左右内缩逻辑 (LRSpacing)
        let inset = appearanceSnapshot.layout.tabSelectedMetailLRSpacing
        let finalFrame = CGRect(
            x: convertedFrame.origin.x + inset,
            y: convertedFrame.origin.y,
            width: max(convertedFrame.width - (inset * 2), 0),
            height: convertedFrame.height
        )
        
        let cornerRadius = finalFrame.height / 2

        let frameChanged = sharedSelectionMaskView.frame != finalFrame
        let cornerRadiusChanged = sharedSelectionMaskView.layer.cornerRadius != cornerRadius
            || sharedMaskGlassView.layer.cornerRadius != cornerRadius
        guard frameChanged || cornerRadiusChanged else { return }
        
        let layoutUpdates = {
            self.sharedSelectionMaskView.frame = finalFrame
            self.sharedSelectionMaskView.layer.cornerRadius = cornerRadius
            self.sharedMaskGlassView.layer.cornerRadius = cornerRadius
            self.sharedMaskGlassView.layer.cornerCurve = .continuous
        }
        
        // 仅在非首次加载且开启了动画时执行 Spring 过渡
        if animated && !UIAccessibility.isReduceMotionEnabled && sharedSelectionMaskView.frame != .zero {
            // 参数调整说明：damping 0.75 带有轻微Q弹的高级感，velocity 响应灵敏
            UIView.animate(withDuration: 0.35,
                           delay: 0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 0.2,
                           options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
                           animations: {
                layoutUpdates()
            })
        } else {
            layoutUpdates()
        }
    }

}
