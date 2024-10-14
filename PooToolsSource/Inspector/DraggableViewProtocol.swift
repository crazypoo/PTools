//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol DraggableViewProtocol: UIView {
    var draggableAreaLayoutGuide: UILayoutGuide { get }
    var draggableAreaAdjustedContentInset: UIEdgeInsets { get }
    var draggableView: UIView { get }
    var isDragging: Bool { get set }
}

extension DraggableViewProtocol {
    func dragView(with gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)

        draggableView.center = location

        switch gesture.state {
        case .possible, .began, .changed:
            isDragging = true

        case .cancelled, .failed:
            isDragging = false

        case .ended:
            isDragging = false
            finalizeDrag()

        @unknown default:
            return
        }
    }
}

private extension DraggableViewProtocol {
    var draggableAreaFrame: CGRect {
        CGRect(
            x: draggableAreaLayoutGuide.layoutFrame.minX + draggableAreaAdjustedContentInset.left,
            y: draggableAreaLayoutGuide.layoutFrame.minY + draggableAreaAdjustedContentInset.top,
            width: draggableAreaLayoutGuide.layoutFrame.width - draggableAreaAdjustedContentInset.horizontalInsets,
            height: draggableAreaLayoutGuide.layoutFrame.height - draggableAreaAdjustedContentInset.verticalInsets
        )
    }

    var draggableViewFrame: CGRect {
        draggableView.convert(draggableView.bounds, to: self)
    }

    func adjustedDraggableAreaFrame() -> CGRect {
        let width = draggableView.frame.width
        let height = draggableView.frame.height

        let halfWidth = width / 2
        let halfHeight = height / 2

        return CGRect(
            x: min(draggableAreaFrame.maxX, draggableAreaFrame.origin.x + halfWidth),
            y: min(draggableAreaFrame.maxY, draggableAreaFrame.origin.y + halfHeight),
            width: max(0, draggableAreaFrame.width - width),
            height: max(0, draggableAreaFrame.height - height)
        )
    }

    func centerInsideDraggableArea(from location: CGPoint) -> CGPoint {
        let adjustedDraggableAreaFrame = adjustedDraggableAreaFrame()

        let ratioX = min(1, location.x / adjustedDraggableAreaFrame.maxX)
        let ratioY = min(1, location.y / adjustedDraggableAreaFrame.maxY)

        var finalX = max(adjustedDraggableAreaFrame.minX, adjustedDraggableAreaFrame.maxX * ratioX)
        var finalY = max(adjustedDraggableAreaFrame.minY, adjustedDraggableAreaFrame.maxY * ratioY)

        if draggableView.frame.width > adjustedDraggableAreaFrame.width {
            finalX = draggableAreaFrame.midX
        }

        if draggableView.frame.height > adjustedDraggableAreaFrame.height {
            finalY = draggableAreaFrame.midY
        }

        let point = CGPoint(x: finalX, y: finalY)

        return point
    }

    func finalizeDrag() {
        let center = centerInsideDraggableArea(from: draggableView.center)

        animate(withDuration: .long, options: [.beginFromCurrentState, .curveEaseIn]) {
            self.draggableView.center = center
        }
    }
}
