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

/// 分佈方向
public enum ConstraintAxis: Int {
    case horizontal // 水平
    case vertical   // 垂直
}

/// 對一組視圖進行統一佈局控制的封裝
public struct ConstraintGroup {
    internal let array: [ConstraintView]
    
    internal init(array: [ConstraintView]) {
        self.array = array
    }

    /// 預先建立 SnapKit 約束（不會立即生效）
    public func prepareConstraints(_ closure: (_ make: ConstraintMaker) -> Void) -> [Constraint] {
        guard !array.isEmpty else { return [] }
        return array.flatMap { $0.snp.prepareConstraints(closure) }
    }

    /// 對整個視圖陣列新增 SnapKit 約束
    public func makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        guard !array.isEmpty else { return }
        array.forEach { $0.snp.makeConstraints(closure) }
    }

    /// 移除並重建 SnapKit 約束
    public func remakeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        guard !array.isEmpty else { return }
        array.forEach { $0.snp.remakeConstraints(closure) }
    }

    /// 更新現有的 SnapKit 約束
    public func updateConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        guard !array.isEmpty else { return }
        array.forEach { $0.snp.updateConstraints(closure) }
    }

    /// 移除所有 SnapKit 約束
    public func removeConstraints() {
        guard !array.isEmpty else { return }
        array.forEach { $0.snp.removeConstraints() }
    }

    /// 沿水平或垂直方向等間距分佈視圖，寬度或高度等比
    public func distributeViewsAlong(axisType: ConstraintAxis,
                                     fixedSpacing: CGFloat = 0,
                                     leadSpacing: CGFloat = 0,
                                     tailSpacing: CGFloat = 0) {
        guard array.count > 1, let superview = commonSuperview() else { return }
        var prev: ConstraintView?

        for (index, view) in array.enumerated() {
            view.snp.makeConstraints { make in
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

    /// 沿方向固定每個 item 長度，讓剩餘空間平均分配
    public func distributeViewsAlong(axisType: ConstraintAxis,
                                     fixedItemLength: CGFloat = 0,
                                     leadSpacing: CGFloat = 0,
                                     tailSpacing: CGFloat = 0) {
        guard array.count > 1, let superview = commonSuperview() else { return }

        for (index, view) in array.enumerated() {
            view.snp.makeConstraints { make in
                switch axisType {
                case .horizontal:
                    make.width.equalTo(fixedItemLength)
                    if index == 0 {
                        make.left.equalTo(superview).offset(leadSpacing)
                    } else if index == array.count - 1 {
                        make.right.equalTo(superview).offset(-tailSpacing)
                    } else {
                        let offset = ConstraintGroup.interpolatedOffset(index: index,
                                                                        count: array.count,
                                                                        lead: leadSpacing,
                                                                        tail: tailSpacing,
                                                                        size: fixedItemLength)
                        make.right.equalTo(superview)
                            .multipliedBy(CGFloat(index) / CGFloat(array.count - 1))
                            .offset(offset)
                    }
                case .vertical:
                    make.height.equalTo(fixedItemLength)
                    if index == 0 {
                        make.top.equalTo(superview).offset(leadSpacing)
                    } else if index == array.count - 1 {
                        make.bottom.equalTo(superview).offset(-tailSpacing)
                    } else {
                        let offset = ConstraintGroup.interpolatedOffset(index: index,
                                                                        count: array.count,
                                                                        lead: leadSpacing,
                                                                        tail: tailSpacing,
                                                                        size: fixedItemLength)
                        make.bottom.equalTo(superview)
                            .multipliedBy(CGFloat(index) / CGFloat(array.count - 1))
                            .offset(offset)
                    }
                }
            }
        }
    }

    /// 固定 item 尺寸，自動排成數獨矩陣（九宮格）
    public func distributeSudokuViews(fixedItemWidth: CGFloat,
                                      fixedItemHeight: CGFloat,
                                      warpCount: Int,
                                      edgeInset: ConstraintEdgeInsets = .zero) {
        guard array.count > 1, warpCount > 0, let superview = commonSuperview() else { return }

        let rowCount = (array.count + warpCount - 1) / warpCount

        for (index, view) in array.enumerated() {
            let row = index / warpCount
            let column = index % warpCount

            view.snp.makeConstraints { make in
                make.width.equalTo(fixedItemWidth)
                make.height.equalTo(fixedItemHeight)

                if row == 0 {
                    make.top.equalTo(superview).offset(edgeInset.top)
                }
                if row == rowCount - 1 {
                    make.bottom.equalTo(superview).offset(-edgeInset.bottom)
                }

                if column == 0 {
                    make.left.equalTo(superview).offset(edgeInset.left)
                }
                if column == warpCount - 1 {
                    make.right.equalTo(superview).offset(-edgeInset.right)
                }
            }
        }
    }

    /// 等高等寬九宮格分佈，固定間距
    public func distributeSudokuViews(fixedLineSpacing: CGFloat,
                                      fixedInteritemSpacing: CGFloat,
                                      warpCount: Int,
                                      edgeInset: ConstraintEdgeInsets = .zero) {
        guard array.count > 1, warpCount > 0, let superview = commonSuperview() else { return }

        let rowCount = (array.count + warpCount - 1) / warpCount

        for (index, view) in array.enumerated() {
            let row = index / warpCount
            let column = index % warpCount

            view.snp.makeConstraints { make in
                if row == 0 {
                    make.top.equalTo(superview).offset(edgeInset.top)
                } else {
                    make.top.equalTo(array[index - warpCount].snp.bottom).offset(fixedLineSpacing)
                }

                if column == 0 {
                    make.left.equalTo(superview).offset(edgeInset.left)
                } else {
                    make.left.equalTo(array[index - 1].snp.right).offset(fixedInteritemSpacing)
                }

                if row == rowCount - 1 {
                    make.bottom.equalTo(superview).offset(-edgeInset.bottom)
                }
                if column == warpCount - 1 {
                    make.right.equalTo(superview).offset(-edgeInset.right)
                }

                if index > 0 {
                    make.width.height.equalTo(array[0])
                }
            }
        }
    }

    /// 取得所有視圖的共同 superview
    private func commonSuperview() -> ConstraintView? {
        guard let first = array.first else { return nil }
        return array.dropFirst().reduce(first) { result, view in
            result?.closestCommonSuperview(with: view)
        }
    }

    /// 補間計算中間 item 的 offset（用於平均分佈）
    private static func interpolatedOffset(index: Int,
                                           count: Int,
                                           lead: CGFloat,
                                           tail: CGFloat,
                                           size: CGFloat) -> CGFloat {
        return (1 - CGFloat(index) / CGFloat(count - 1)) * (size + lead)
            - CGFloat(index) * tail / CGFloat(count - 1)
    }
}

extension ConstraintView {
    /// 找出與另一視圖的最近共同 superview
    fileprivate func closestCommonSuperview(with view: ConstraintView?) -> ConstraintView? {
        var currentSuperview = self
        while let superview = currentSuperview.superview {
            if view?.isDescendant(of: superview) == true {
                return superview
            }
            currentSuperview = superview
        }
        return nil
    }
}

/// 快捷存取視圖陣列的 ConstraintGroup
public extension Array where Element: ConstraintView {
    var constraintGroup: ConstraintGroup {
        return ConstraintGroup(array: self)
    }
}
