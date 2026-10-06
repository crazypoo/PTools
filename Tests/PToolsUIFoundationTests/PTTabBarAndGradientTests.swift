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

    // English: Selection and offset inputs do not participate in content-size resolution.
    // Español: La selección y el offset no participan en el cálculo del tamaño del contenido.
    // 中文：选中背景和内容偏移不会参与真实内容尺寸计算。
    func testSelectionAndOffsetDoNotChangeResolvedContentSize() {
        let base = PTTabBarLayoutEngine.contentSize(baseSize: 32, insets: .zero)
        let withSelection = PTTabBarLayoutEngine.contentSize(baseSize: 32, insets: .zero)
        let withOffset = PTTabBarLayoutEngine.contentSize(baseSize: 32, insets: .zero)

        XCTAssertEqual(base, CGSize(width: 32, height: 32))
        XCTAssertEqual(withSelection, base)
        XCTAssertEqual(withOffset, base)
    }

    // English: Verifies that positive and negative insets change the resolved content size.
    // Español: Verifica que los insets positivos y negativos cambian el tamaño real del contenido.
    // 中文：验证正负内边距都会真正改变内容尺寸。
    func testContentSizeResolverSupportsShrinkAndExpansion() {
        XCTAssertEqual(
            PTTabBarLayoutEngine.contentSize(
                baseSize: 32,
                insets: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
            ),
            CGSize(width: 24, height: 28)
        )
        XCTAssertEqual(
            PTTabBarLayoutEngine.contentSize(
                baseSize: 32,
                insets: UIEdgeInsets(top: -2, left: -2, bottom: -2, right: -2)
            ),
            CGSize(width: 36, height: 36)
        )
    }

    // English: Invalid values are ignored and negative insets cannot expand beyond the safety scale.
    // Español: Los valores inválidos se ignoran y los insets negativos no superan la escala de seguridad.
    // 中文：非法数值会被忽略，负内边距不会超过安全放大倍率。
    func testContentSizeResolverRejectsInvalidValuesAndCapsExpansion() {
        let result = PTTabBarLayoutEngine.contentSize(
            baseSize: 32,
            insets: UIEdgeInsets(top: -CGFloat.infinity,
                                 left: -1000,
                                 bottom: CGFloat.nan,
                                 right: -1000)
        )

        XCTAssertEqual(result, CGSize(width: 64, height: 32))
    }

    // English: The real content view, not the outer container, receives the resolved size.
    // Español: La vista de contenido real, no el contenedor exterior, recibe el tamaño resuelto.
    // 中文：真实 content.view 而不是外围容器接收解析后的尺寸。
    func testItemContentInsetsChangeContentViewBounds() {
        let insets = UIEdgeInsets(top: 3, left: 4, bottom: 5, right: 6)
        let layout = PTTabBarLayoutAppearance(tabBottomSpacing: 0,
                                               tabContentSpacing: 0,
                                               tabTopSpacing: 0,
                                               tabItemContentInsets: insets)
        let appearance = PTTabBarAppearance(selectedFont: .systemFont(ofSize: 13), layout: layout)
        let item = PTTabBarItemView(content: PTTabBarImageContent(normal: UIImage(systemName: "photo") ?? UIImage()),
                                    title: "",
                                    appearance: appearance)
        item.frame = CGRect(x: 0, y: 0, width: 120, height: 100)
        item.layoutIfNeeded()

        let baseSize = PTTabBarLayoutEngine.itemImageSize(
            barHeight: CGFloat.kTabbarHeight,
            safeAreaHeight: 0,
            titleHeight: 15,
            appearance: layout
        )
        XCTAssertEqual(item.imageContent.bounds.size,
                       CGSize(width: baseSize - insets.left - insets.right,
                              height: baseSize - insets.top - insets.bottom))
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
