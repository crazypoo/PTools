import UIKit
import XCTest
@testable import PooToolsImageEditor

@MainActor
final class PTImageEditorInteractionRegressionTests: XCTestCase {
    func testUndoRedoHistoryDiscardsFutureActionsAfterNewEdit() {
        let manager = PTMediaEditManager()
        XCTAssertTrue(manager.actions.isEmpty)
        XCTAssertTrue(manager.redoActions.isEmpty)

        let original = PTAdjustStatus()
        var contrast = original
        contrast.contrast = 0.5
        var saturation = original
        saturation.saturation = -0.5

        manager.storeAction(.adjust(oldStatus: original, newStatus: contrast))
        XCTAssertEqual(manager.actions.count, 1)
        XCTAssertEqual(manager.redoActions.count, 1)
        manager.undoAction()
        XCTAssertTrue(manager.actions.isEmpty)
        XCTAssertEqual(manager.redoActions.count, 1)

        manager.redoAction()
        XCTAssertEqual(manager.actions.count, 1)
        manager.undoAction()
        manager.storeAction(.adjust(oldStatus: original, newStatus: saturation))
        XCTAssertEqual(manager.actions.count, 1)
        XCTAssertEqual(manager.redoActions.count, 1)
    }

    func testRatioPreviewKeepsBothPortraitAndLandscapeGeometry() {
        let cell = PTImageCutRatioCell(frame: CGRect(x: 0, y: 0, width: 88, height: 108))
        let image = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 80)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
        }
        guard let preview = cell.contentView.subviews.compactMap({ $0 as? UIImageView }).first else {
            return XCTFail("Ratio preview image view is missing")
        }

        cell.configureCell(image: image, ratio: .wh16x9)
        cell.layoutIfNeeded()
        cell.contentView.layoutIfNeeded()
        XCTAssertGreaterThan(preview.bounds.width, preview.bounds.height)

        cell.configureCell(image: image, ratio: .wh9x16)
        cell.layoutIfNeeded()
        cell.contentView.layoutIfNeeded()
        XCTAssertLessThan(preview.bounds.width, preview.bounds.height)
        XCTAssertLessThanOrEqual(preview.bounds.width, cell.bounds.width)
        XCTAssertLessThanOrEqual(preview.bounds.height, cell.bounds.height)
    }

    func testFixedRatioCropCornerDoesNotLeaveViewport() {
        let bounds = CGRect(x: 0, y: 0, width: 350, height: 520)
        let initial = CGRect(x: 75, y: 120, width: 200, height: 150)
        for edge: PTClipPanEdge in [.topLeft, .topRight, .bottomLeft, .bottomRight] {
            let frame = PTClipEngine.resizedClipFrame(
                from: initial, edge: edge,
                translation: CGPoint(x: 9999, y: -9999),
                aspectRatio: 4.0 / 3.0,
                inside: bounds,
                minimumSize: CGSize(width: 45, height: 45)
            )
            XCTAssertGreaterThanOrEqual(frame.minX, bounds.minX - 0.001)
            XCTAssertGreaterThanOrEqual(frame.minY, bounds.minY - 0.001)
            XCTAssertLessThanOrEqual(frame.maxX, bounds.maxX + 0.001)
            XCTAssertLessThanOrEqual(frame.maxY, bounds.maxY + 0.001)
            XCTAssertEqual(frame.width / frame.height, 4.0 / 3.0, accuracy: 0.001)
        }
    }
}
