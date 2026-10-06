import UIKit
import XCTest
@testable import ptools

// English: Covers the separation between TabBar selection geometry and item content geometry.
// Español: Cubre la separación entre la geometría de selección y la geometría del contenido del TabBar.
// 中文：覆盖 TabBar 选中背景几何与项目内容几何的解耦。
@MainActor
final class PTTabBarAndGradientTests: XCTestCase {
    func testSelectionInsetsClampToTheItemBounds() {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        let result = PTTabBarLayoutEngine.selectionFrame(
            frame: frame,
            insets: UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
        )

        XCTAssertEqual(result, CGRect(x: 5, y: 10, width: 90, height: 30))
    }

    func testOversizedAndNegativeSelectionInsetsNeverCreateNegativeGeometry() {
        let result = PTTabBarLayoutEngine.selectionFrame(
            frame: CGRect(x: 2, y: 4, width: 10, height: 8),
            insets: UIEdgeInsets(top: -2, left: 100, bottom: 100, right: -4)
        )

        XCTAssertGreaterThanOrEqual(result.width, 0)
        XCTAssertGreaterThanOrEqual(result.height, 0)
        XCTAssertTrue(result.minX.isFinite)
        XCTAssertTrue(result.minY.isFinite)
    }

    func testSelectionInsetsDoNotChangeItemImageSize() {
        let layoutWithoutSelection = PTTabBarLayoutAppearance(tabSelectedMetailInsets: .zero)
        let layoutWithSelection = PTTabBarLayoutAppearance(
            tabSelectedMetailInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )

        let original = PTTabBarLayoutEngine.itemImageSize(
            barHeight: 49,
            safeAreaHeight: 0,
            titleHeight: 13,
            appearance: layoutWithoutSelection
        )
        let changed = PTTabBarLayoutEngine.itemImageSize(
            barHeight: 49,
            safeAreaHeight: 0,
            titleHeight: 13,
            appearance: layoutWithSelection
        )

        XCTAssertEqual(original, changed)
    }

    func testContentOffsetDoesNotChangeItemImageSize() {
        let layout = PTTabBarLayoutAppearance(tabItemContentOffset: UIOffset(horizontal: 0, vertical: -3))
        let imageSize = PTTabBarLayoutEngine.itemImageSize(
            barHeight: 49,
            safeAreaHeight: 0,
            titleHeight: 13,
            appearance: layout
        )

        XCTAssertEqual(imageSize, 29)
    }

    func testLabelUsesBackingBackgroundInsteadOfBackgroundGradientSublayer() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 160, height: 50))
        label.text = "PTools"
        label.backgroundGradient(type: .LeftToRight,
                                 colors: [.systemBlue, .systemPurple],
                                 radius: 12)
        label.layoutIfNeeded()

        XCTAssertFalse(label.layer.sublayers?.contains(where: { $0.name == "PTSuperBg" }) ?? false)
        XCTAssertEqual(label.text, "PTools")
    }

    func testImageViewUsesBackingBackgroundAndKeepsImage() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        let image = UIImage(systemName: "photo")
        imageView.image = image
        imageView.backgroundGradient(type: .TopToBottom,
                                     colors: [.systemOrange, .systemRed],
                                     radius: 20)
        imageView.layoutIfNeeded()

        XCTAssertFalse(imageView.layer.sublayers?.contains(where: { $0.name == "PTSuperBg" }) ?? false)
        XCTAssertTrue(imageView.image === image)
    }

    func testPlainViewRetainsSublayerGradientPath() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        view.backgroundGradient(type: .LeftToRight,
                                colors: [.systemBlue, .systemPurple],
                                radius: 12)
        view.layoutIfNeeded()

        XCTAssertTrue(view.layer.sublayers?.contains(where: { $0.name == "PTSuperBg" }) ?? false)
    }

    func testClearingGradientRestoresOriginalBackgroundColor() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 160, height: 50))
        let original = UIColor.systemBackground
        label.backgroundColor = original
        label.backgroundGradient(type: .LeftToRight,
                                 colors: [.systemBlue, .systemPurple],
                                 radius: 12)
        label.superGradient()

        XCTAssertEqual(label.backgroundColor, original)
        XCTAssertFalse(label.layer.sublayers?.contains(where: { $0.name == "PTSuperBg" }) ?? false)
    }
}
