//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension LengthMeasurementView {
    final class ArrowView: BaseView {
        var axis: NSLayoutConstraint.Axis {
            didSet {
                setNeedsDisplay()
            }
        }

        var color: UIColor {
            didSet {
                setNeedsDisplay()
            }
        }

        var gapSize: CGSize = .zero {
            didSet {
                setNeedsDisplay()
            }
        }

        init(axis: NSLayoutConstraint.Axis, color: UIColor, frame: CGRect = .zero) {
            self.axis = axis
            self.color = color

            super.init(frame: frame)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func setup() {
            super.setup()

            autoresizingMask = [.flexibleWidth, .flexibleWidth]

            isOpaque = false

            contentMode = .redraw
        }

        override func draw(_ rect: CGRect) {
            switch axis {
            case .vertical:
                IconKit.drawSizeArrowVertical(color: color, gapHeight: gapSize.height, frame: rect)

            case .horizontal:
                IconKit.drawSizeArrowHorizontal(color: color, gapWidth: gapSize.width, frame: rect)

            @unknown default:
                break
            }
        }
    }
}
