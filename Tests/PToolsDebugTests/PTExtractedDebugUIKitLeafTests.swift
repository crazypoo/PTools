import UIKit
import XCTest
import PToolsDebugConsoleUI
import PToolsDebugMetricsUI
@testable import PooToolsDEBUG

@MainActor
final class PTExtractedDebugUIKitLeafTests: XCTestCase {
    func testConsoleWindowDoesNotChooseAnUnrelatedScene() {
        let window = PTConsoleWindow.window(for: nil)
        XCTAssertTrue(window === PTConsoleWindow.shared)
        // No default root view means taps cannot intercept the host app.
        XCTAssertNil(window.hitTest(CGPoint(x: 4, y: 4), with: nil))
    }

    func testMetricTrackGridDrawsWithoutOwningARecorder() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 160, height: 120))
        let image = renderer.image { _ in
            PTDebugMetricsTrackRenderer.drawTrackGrid(
                titles: ["FPS", "CPU"], width: 160,
                context: UIGraphicsGetCurrentContext())
        }
        XCTAssertNotNil(image.cgImage)
    }
}
