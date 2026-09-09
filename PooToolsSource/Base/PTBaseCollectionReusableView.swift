//
//  PT.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

// English: Reusable collection views are UI state and must stay on MainActor.
// Español: Las vistas reutilizables de colección son estado de UI y deben permanecer en MainActor.
// 中文：可复用集合视图属于 UI 状态，必须固定在 MainActor 上。
@MainActor
@objcMembers
open class PTBaseCollectionReusableView: UICollectionReusableView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupReusableView()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupReusableView()
    }

    private func setupReusableView() {
        isUserInteractionEnabled = true
    }

    open class func cellSize() -> CGSize {
        CGSize(width: 1, height: 1)
    }

    open class func cellIdentifier() -> String {
        String(describing: Self.self)
    }
    
    open class func cellSizeByClass() -> NSNumber {
        NSNumber(value: true)
    }

    open class func cellSizeValue() -> NSValue {
        NSValue(cgSize: cellSize())
    }
}
