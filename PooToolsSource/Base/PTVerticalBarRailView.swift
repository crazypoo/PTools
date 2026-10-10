//
//  PTVerticalBarRailView.swift
//  PooTools
//
//  English: Keep the optional custom vertical rail as one visual surface.
//  Español: Mantiene la rail vertical personalizada opcional como una sola superficie visual.
//  中文：将可选的自定义垂直 Rail 保持为一个独立视觉表面。
//

import UIKit

@MainActor
open class PTVerticalBarRailView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isAccessibilityElement = false
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isAccessibilityElement = false
    }
}
