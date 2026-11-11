import UIKit
import XCTest
@testable import PooToolsImageEditor

@MainActor
final class PTImageCropInteractionTests: XCTestCase {
    private let bounds = CGRect(x: 15, y: 70, width: 320, height: 420)
    private let start = CGRect(x: 75, y: 150, width: 200, height: 200)

    func testFixedRatioCornersStayInsideBoundsAndRetainOppositeAnchor() {
        let edges: [(PTClipPanEdge, CGPoint)] = [
            (.topLeft, CGPoint(x: -500, y: -500)),
            (.topRight, CGPoint(x: 500, y: -500)),
            (.bottomLeft, CGPoint(x: -500, y: 500)),
            (.bottomRight, CGPoint(x: 500, y: 500))
        ]
        for (edge, delta) in edges {
            let result = PTClipEngine.resizedClipFrame(
                from: start, edge: edge, translation: delta, aspectRatio: 1,
                inside: bounds, minimumSize: CGSize(width: 45, height: 45)
            )
            XCTAssertGreaterThanOrEqual(result.minX, bounds.minX - 0.001)
            XCTAssertGreaterThanOrEqual(result.minY, bounds.minY - 0.001)
            XCTAssertLessThanOrEqual(result.maxX, bounds.maxX + 0.001)
            XCTAssertLessThanOrEqual(result.maxY, bounds.maxY + 0.001)
            XCTAssertEqual(result.width, result.height, accuracy: 0.001)
            switch edge {
            case .topLeft:
                XCTAssertEqual(result.maxX, start.maxX, accuracy: 0.001)
                XCTAssertEqual(result.maxY, start.maxY, accuracy: 0.001)
            case .topRight:
                XCTAssertEqual(result.minX, start.minX, accuracy: 0.001)
                XCTAssertEqual(result.maxY, start.maxY, accuracy: 0.001)
            case .bottomLeft:
                XCTAssertEqual(result.maxX, start.maxX, accuracy: 0.001)
                XCTAssertEqual(result.minY, start.minY, accuracy: 0.001)
            case .bottomRight:
                XCTAssertEqual(result.minX, start.minX, accuracy: 0.001)
                XCTAssertEqual(result.minY, start.minY, accuracy: 0.001)
            default: XCTFail("Unexpected edge")
            }
        }
    }

    func testFixedRatioSideDragKeepsTheOtherAxisCentered() {
        for edge: PTClipPanEdge in [.top, .bottom, .left, .right] {
            let result = PTClipEngine.resizedClipFrame(
                from: start, edge: edge,
                translation: CGPoint(x: -40, y: 80),
                aspectRatio: 4.0 / 3.0,
                inside: bounds,
                minimumSize: CGSize(width: 45, height: 45)
            )
            XCTAssertEqual(result.width / result.height, 4.0 / 3.0, accuracy: 0.001)
            XCTAssertGreaterThanOrEqual(result.minX, bounds.minX - 0.001)
            XCTAssertGreaterThanOrEqual(result.minY, bounds.minY - 0.001)
            XCTAssertLessThanOrEqual(result.maxX, bounds.maxX + 0.001)
            XCTAssertLessThanOrEqual(result.maxY, bounds.maxY + 0.001)
            if edge == .left || edge == .right {
                XCTAssertEqual(result.midY, start.midY, accuracy: 0.001)
            } else {
                XCTAssertEqual(result.midX, start.midX, accuracy: 0.001)
            }
        }
    }

    func testFreeCropClampsToBoundsWithoutMovingUnselectedEdges() {
        let result = PTClipEngine.resizedClipFrame(
            from: start, edge: .left,
            translation: CGPoint(x: -1000, y: 999),
            aspectRatio: 0, inside: bounds,
            minimumSize: CGSize(width: 45, height: 45)
        )
        XCTAssertEqual(result.minX, bounds.minX)
        XCTAssertEqual(result.maxX, start.maxX)
        XCTAssertEqual(result.minY, start.minY)
        XCTAssertEqual(result.maxY, start.maxY)
    }

    func testCenteringMaintainsImageFocusEvenAtMaximumZoom() {
        let result = PTClipEngine.centeredContentOffset(
            focusInViewport: CGPoint(x: 160, y: 260),
            oldContentOffset: CGPoint(x: 300, y: 200),
            oldZoomScale: 10,
            newZoomScale: 10,
            newClipFrame: CGRect(x: 30, y: 80, width: 270, height: 300),
            contentSize: CGSize(width: 1500, height: 1500)
        )
        XCTAssertEqual(result.x, 315, accuracy: 0.001)
        XCTAssertEqual(result.y, 180, accuracy: 0.001)
    }

    func testCropGestureDoesNotInterceptCanvasCenter() {
        final class Context: PTClipEngineContext {
            var engineMaxClipFrame = CGRect(x: 0, y: 0, width: 400, height: 600)
            var engineMinClipSize = CGSize(width: 45, height: 45)
        }
        let context = Context()
        let engine = PTClipEngine(context: context, initialRatio: .custom)
        engine.clipBoxFrame = CGRect(x: 60, y: 100, width: 200, height: 240)
        XCTAssertFalse(engine.canBeginPan(at: CGPoint(x: 160, y: 220)))
        XCTAssertTrue(engine.canBeginPan(at: CGPoint(x: 60, y: 100)))
        XCTAssertTrue(engine.canBeginPan(at: CGPoint(x: 160, y: 100)))
        XCTAssertFalse(engine.canBeginPan(at: CGPoint(x: 5, y: 5)))
    }
}
