//
//  PTAdaptiveBarDebugOverlay.swift
//  PooTools
//
//  English: Draw adaptive-bar rectangles only for DEBUG inspection.
//  Español: Dibuja rectángulos de las barras adaptativas solo para inspección DEBUG.
//  中文：仅在 DEBUG 下绘制自适应 Bar 的诊断矩形。
//

import UIKit

@MainActor
public final class PTAdaptiveBarDebugOverlay: UIView {
    public var geometry: PTAdaptiveBarGeometry? {
        didSet { setNeedsDisplay() }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    public override func draw(_ rect: CGRect) {
        #if DEBUG
        guard let geometry else { return }
        let entries: [(CGRect, UIColor)] = [
            (geometry.contentSafeRect, .systemGreen),
            (geometry.navItemsRect, .systemBlue),
            (geometry.tabItemsRect, .systemOrange),
            (geometry.accessoryRect, .systemPurple)
        ]
        for (frame, color) in entries where !frame.isEmpty {
            color.withAlphaComponent(0.75).setStroke()
            UIBezierPath(rect: frame).stroke()
        }

        for frame in geometry.reservedRegionFrames where !frame.isEmpty {
            UIColor.systemRed.withAlphaComponent(0.8).setStroke()
            UIBezierPath(rect: frame).stroke()
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.label
        ]
        geometry.debugSummary.draw(in: CGRect(x: 8, y: 8, width: max(0, bounds.width - 16), height: 80),
                                   withAttributes: attributes)
        #endif
    }
}
