//
//  PTSnapKitEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 4/1/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation
import SnapKit

#if os(iOS) || os(tvOS)
import UIKit
public typealias ConstraintView = UIView
public typealias ConstraintEdgeInsets = UIEdgeInsets
#else
import AppKit
public typealias ConstraintView = NSView
public typealias ConstraintEdgeInsets = NSEdgeInsets
extension NSEdgeInsets {
    public static let zero = NSEdgeInsetsZero
}
#endif

/// 分布方向
public enum ConstraintAxis: Int {
    case horizontal // 水平
    case vertical   // 垂直
}

/// 交叉轴对齐方式（新增：用于解决单轴分布时另一条轴线约束缺失的问题）
public enum ConstraintCrossAxisAlignment {
    case fill       // 填满父视图
    case center     // 居中对齐
    case leading    // 顶部或左侧对齐
    case trailing   // 底部或右侧对齐
}

/// 对一组视图进行统一布局控制的封装
public struct ConstraintGroup {
    internal let array: [ConstraintView]
    
    internal init(array: [ConstraintView]) {
        self.array = array
    }

    // MARK: - 基础 SnapKit 封装
    
    public func prepareConstraints(_ closure: (_ make: ConstraintMaker) -> Void) -> [Constraint] {
        guard !array.isEmpty else { return [] }
        return array.flatMap { $0.snp.prepareConstraints(closure) }
    }

    public func makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        array.forEach { $0.snp.makeConstraints(closure) }
    }

    public func remakeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        array.forEach { $0.snp.remakeConstraints(closure) }
    }

    public func updateConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        array.forEach { $0.snp.updateConstraints(closure) }
    }

    public func removeConstraints() {
        array.forEach { $0.snp.removeConstraints() }
    }

    // MARK: - 单轴分布布局
    
    /// 沿水平或垂直方向等间距分布视图，宽度或高度等比
    /// - 补充了 crossAxisAlignment 防止交叉轴报约束缺失警告
    public func distributeViewsAlong(axisType: ConstraintAxis,
                                     fixedSpacing: CGFloat = 0,
                                     leadSpacing: CGFloat = 0,
                                     tailSpacing: CGFloat = 0,
                                     crossAxisAlignment: ConstraintCrossAxisAlignment = .fill) {
        guard array.count > 1, let superview = commonSuperview() else { return }
        var prev: ConstraintView?

        for (index, view) in array.enumerated() {
            view.snp.makeConstraints { make in
                applyCrossAxis(make: make, axis: axisType, alignment: crossAxisAlignment, superview: superview)
                
                switch axisType {
                case .horizontal:
                    if let prev = prev {
                        make.left.equalTo(prev.snp.right).offset(fixedSpacing)
                        make.width.equalTo(prev)
                        if index == array.count - 1 {
                            make.right.equalTo(superview).offset(-tailSpacing)
                        }
                    } else {
                        make.left.equalTo(superview).offset(leadSpacing)
                    }
                case .vertical:
                    if let prev = prev {
                        make.top.equalTo(prev.snp.bottom).offset(fixedSpacing)
                        make.height.equalTo(prev)
                        if index == array.count - 1 {
                            make.bottom.equalTo(superview).offset(-tailSpacing)
                        }
                    } else {
                        make.top.equalTo(superview).offset(leadSpacing)
                    }
                }
            }
            prev = view
        }
    }

    /// 沿方向固定每个 item 尺寸，让剩余空间平均分配
    public func distributeViewsAlong(axisType: ConstraintAxis,
                                     fixedItemLength: CGFloat = 0,
                                     leadSpacing: CGFloat = 0,
                                     tailSpacing: CGFloat = 0,
                                     crossAxisAlignment: ConstraintCrossAxisAlignment = .fill) {
        guard array.count > 1, let superview = commonSuperview() else { return }

        for (index, view) in array.enumerated() {
            view.snp.makeConstraints { make in
                applyCrossAxis(make: make, axis: axisType, alignment: crossAxisAlignment, superview: superview)
                
                switch axisType {
                case .horizontal:
                    make.width.equalTo(fixedItemLength)
                    if index == 0 {
                        make.left.equalTo(superview).offset(leadSpacing)
                    } else if index == array.count - 1 {
                        make.right.equalTo(superview).offset(-tailSpacing)
                    } else {
                        let offset = ConstraintGroup.interpolatedOffset(index: index, count: array.count, lead: leadSpacing, tail: tailSpacing, size: fixedItemLength)
                        make.right.equalTo(superview).multipliedBy(CGFloat(index) / CGFloat(array.count - 1)).offset(offset)
                    }
                case .vertical:
                    make.height.equalTo(fixedItemLength)
                    if index == 0 {
                        make.top.equalTo(superview).offset(leadSpacing)
                    } else if index == array.count - 1 {
                        make.bottom.equalTo(superview).offset(-tailSpacing)
                    } else {
                        let offset = ConstraintGroup.interpolatedOffset(index: index, count: array.count, lead: leadSpacing, tail: tailSpacing, size: fixedItemLength)
                        make.bottom.equalTo(superview).multipliedBy(CGFloat(index) / CGFloat(array.count - 1)).offset(offset)
                    }
                }
            }
        }
    }

    // MARK: - 九宫格矩阵布局
    
    /// 固定 item 尺寸，自动排成数独矩阵（九宫格）- 修复中间元素缺少约束的 bug
    public func distributeSudokuViews(fixedItemWidth: CGFloat,
                                      fixedItemHeight: CGFloat,
                                      warpCount: Int,
                                      edgeInset: ConstraintEdgeInsets = .zero) {
        guard array.count > 0, warpCount > 0, let superview = commonSuperview() else { return }

        let rowCount = (array.count + warpCount - 1) / warpCount

        for (index, view) in array.enumerated() {
            let row = index / warpCount
            let column = index % warpCount

            view.snp.makeConstraints { make in
                make.width.equalTo(fixedItemWidth)
                make.height.equalTo(fixedItemHeight)

                // 水平方向的插值定位（彻底解决中间元素 Ambiguous Layout）
                if warpCount == 1 {
                    make.left.equalTo(superview).offset(edgeInset.left)
                } else {
                    let offsetH = ConstraintGroup.interpolatedOffset(index: column, count: warpCount, lead: edgeInset.left, tail: edgeInset.right, size: fixedItemWidth)
                    make.right.equalTo(superview).multipliedBy(CGFloat(column) / CGFloat(warpCount - 1)).offset(offsetH)
                }
                
                // 垂直方向的插值定位
                if rowCount == 1 {
                    make.top.equalTo(superview).offset(edgeInset.top)
                } else {
                    let offsetV = ConstraintGroup.interpolatedOffset(index: row, count: rowCount, lead: edgeInset.top, tail: edgeInset.bottom, size: fixedItemHeight)
                    make.bottom.equalTo(superview).multipliedBy(CGFloat(row) / CGFloat(rowCount - 1)).offset(offsetV)
                }
            }
        }
    }

    /// 等高等宽九宫格分布，固定间距 - 修复不足一行时的撑爆 Bug
    public func distributeSudokuViews(fixedLineSpacing: CGFloat,
                                      fixedInteritemSpacing: CGFloat,
                                      warpCount: Int,
                                      edgeInset: ConstraintEdgeInsets = .zero) {
        guard array.count > 0, warpCount > 0, let superview = commonSuperview() else { return }

        let rowCount = (array.count + warpCount - 1) / warpCount

        for (index, view) in array.enumerated() {
            let row = index / warpCount
            let column = index % warpCount

            view.snp.makeConstraints { make in
                // 1. 动态宽度计算（防止不足 warpCount 个元素时宽度无法推断）
                let totalHSpacing = edgeInset.left + edgeInset.right + fixedInteritemSpacing * CGFloat(warpCount - 1)
                make.width.equalTo(superview).offset(-totalHSpacing).dividedBy(CGFloat(warpCount))

                // 2. 高度对齐第一个元素
                if index > 0 {
                    make.height.equalTo(array[0])
                }

                // 3. X 轴定位
                if column == 0 {
                    make.left.equalTo(superview).offset(edgeInset.left)
                } else {
                    make.left.equalTo(array[index - 1].snp.right).offset(fixedInteritemSpacing)
                }

                // 4. Y 轴定位
                if row == 0 {
                    make.top.equalTo(superview).offset(edgeInset.top)
                } else {
                    make.top.equalTo(array[index - warpCount].snp.bottom).offset(fixedLineSpacing)
                }

                // 5. 将最后一行的底部约束到父视图，允许父视图自适应高度（例如 UIScrollView 或 UITableViewCell）
                if row == rowCount - 1 {
                    make.bottom.equalTo(superview).offset(-edgeInset.bottom)
                }
            }
        }
    }

    // MARK: - 内部辅助方法
    
    /// 取得所有视图的共同 superview（引入 Fast Path 性能优化）
    private func commonSuperview() -> ConstraintView? {
        guard let first = array.first, let firstSuperview = first.superview else { return nil }
        
        // 【性能优化】快速通道：如果所有元素的直接父视图都是同一个，直接返回。
        // 这规避了在多数常规场景下昂贵的层级向上遍历。
        if array.allSatisfy({ $0.superview == firstSuperview }) {
            return firstSuperview
        }
        
        // 慢速通道：递归查找
        return array.dropFirst().reduce(first) { result, view in
            result?.closestCommonSuperview(with: view)
        }
    }

    /// 应用交叉轴对齐约束
    private func applyCrossAxis(make: ConstraintMaker, axis: ConstraintAxis, alignment: ConstraintCrossAxisAlignment, superview: ConstraintView) {
        switch axis {
        case .horizontal:
            switch alignment {
            case .fill:     make.top.bottom.equalTo(superview)
            case .center:   make.centerY.equalTo(superview)
            case .leading:  make.top.equalTo(superview)
            case .trailing: make.bottom.equalTo(superview)
            }
        case .vertical:
            switch alignment {
            case .fill:     make.left.right.equalTo(superview)
            case .center:   make.centerX.equalTo(superview)
            case .leading:  make.left.equalTo(superview)
            case .trailing: make.right.equalTo(superview)
            }
        }
    }

    /// 补间计算中间 item 的 offset（用于平均分布）
    private static func interpolatedOffset(index: Int,
                                           count: Int,
                                           lead: CGFloat,
                                           tail: CGFloat,
                                           size: CGFloat) -> CGFloat {
        guard count > 1 else { return lead }
        return (1 - CGFloat(index) / CGFloat(count - 1)) * (size + lead)
            - CGFloat(index) * tail / CGFloat(count - 1)
    }
}

extension ConstraintView {
    /// 找出与另一视图的最近共同 superview
    fileprivate func closestCommonSuperview(with view: ConstraintView?) -> ConstraintView? {
        var currentSuperview: ConstraintView? = self
        while let superview = currentSuperview {
            if view?.isDescendant(of: superview) == true {
                return superview
            }
            currentSuperview = superview.superview
        }
        return nil
    }
}

/// 快捷存取视图数组的 ConstraintGroup
public extension Array where Element: ConstraintView {
    var constraintGroup: ConstraintGroup {
        return ConstraintGroup(array: self)
    }
}
