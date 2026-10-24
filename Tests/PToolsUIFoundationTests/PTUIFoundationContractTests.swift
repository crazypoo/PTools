import XCTest
@testable import ptools

@MainActor
final class PTUIFoundationContractTests: XCTestCase {
    func testSkeletonConfigurationUsesSafeDefaults() {
        let configuration = PTCollectionViewConfig()

        XCTAssertEqual(configuration.skeletonItemCount, 6)
        XCTAssertEqual(configuration.skeletonCornerRadius, 8)
    }

    func testSnapKitConstraintGroupUsesTheSharedSuperview() {
        let container = UIView(frame: .zero)
        let views = [UIView(), UIView(), UIView()]
        views.forEach(container.addSubview)

        views.constraintGroup.distributeViewsAlong(axisType: .horizontal,
                                                    fixedItemLength: 20,
                                                    leadSpacing: 8,
                                                    tailSpacing: 8,
                                                    crossAxisAlignment: .center)

        container.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        container.layoutIfNeeded()

        XCTAssertEqual(views.first?.superview, container)
        XCTAssertEqual(views.last?.superview, container)
        XCTAssertEqual(views.first?.frame.width ?? 0, 20, accuracy: 0.001)
    }

    func testSkeletonConfigurationAcceptsBoundedCustomValues() {
        let configuration = PTCollectionViewConfig()
        configuration.skeletonItemCount = 12
        configuration.skeletonCornerRadius = 14

        XCTAssertEqual(configuration.skeletonItemCount, 12)
        XCTAssertEqual(configuration.skeletonCornerRadius, 14)
    }

    // English: Keep the new skeleton configuration independent from legacy Diffable content.
    // Español: Mantiene la nueva configuración del skeleton independiente del contenido Diffable heredado.
    // 中文：验证新的骨架配置独立于旧的 Diffable 内容。
    func testSkeletonConfigurationKeepsPresentationPolicies() {
        let configuration = PTCollectionSkeletonConfiguration(
            itemCountMode: .fillViewport(extraRows: 2),
            interactionPolicy: .blocksTouches,
            auxiliaryViewPolicy: .hideWhileVisible,
            showDelay: 0.2,
            minimumVisibleDuration: 0.4
        )

        XCTAssertEqual(configuration.itemCountMode, .fillViewport(extraRows: 2))
        XCTAssertEqual(configuration.interactionPolicy, .blocksTouches)
        XCTAssertEqual(configuration.auxiliaryViewPolicy, .hideWhileVisible)
        XCTAssertEqual(configuration.showDelay, 0.2, accuracy: 0.001)
        XCTAssertEqual(configuration.minimumVisibleDuration, 0.4, accuracy: 0.001)
    }

    // English: Invalid shape values must be sanitized before they reach Core Animation paths.
    // Español: Los valores de forma inválidos deben sanearse antes de llegar a las rutas de Core Animation.
    // 中文：无效的骨架形状参数必须在进入 Core Animation 路径前完成清理。
    func testSkeletonShapeSanitizesInvalidRadius() {
        let shape = PTSkeletonShape.roundedRect(.init(x: 0, y: 0, width: 1, height: 1),
                                                cornerRadius: .infinity)

        XCTAssertEqual(shape.cornerRadius, 0)
    }

    func testSkeletonConfigurationUsesIndependentGeometry() {
        let layout = PTCollectionSkeletonLayout(itemHeight: 72,
                                                 horizontalSpacing: 12,
                                                 verticalSpacing: 16,
                                                 columnCount: 2)

        XCTAssertEqual(layout.itemHeight, 72)
        XCTAssertEqual(layout.horizontalSpacing, 12)
        XCTAssertEqual(layout.verticalSpacing, 16)
        XCTAssertEqual(layout.columnCount, 2)
    }

    func testCustomerAlertMeasurementUsesCapsuleInsetsAndSpacing() {
        let insets = UIEdgeInsets(top: 10, left: 18, bottom: 18, right: 18)
        let font = UIFont.systemFont(ofSize: 15)
        let layout = PTCustomerAlertMeasurement.compactActionLayout(
            buttons: ["Cancel", "Continue"],
            width: 340,
            sectionInsets: insets,
            horizontalSpacing: 12,
            titleHorizontalInsets: 16,
            font: font,
            isAccessibilityCategory: false
        )

        XCTAssertEqual(layout, .horizontal)

        let rowHeights = PTCustomerAlertMeasurement.buttonRowHeights(
            buttons: ["Cancel", "Continue"],
            width: 340,
            layout: layout,
            sectionInsets: insets,
            horizontalSpacing: 12,
            titleHorizontalInsets: 16,
            minimumButtonRowHeight: 50,
            font: font
        )

        XCTAssertEqual(rowHeights.count, 2)
        XCTAssertTrue(rowHeights.allSatisfy { $0 >= 50 })
        XCTAssertEqual(
            PTCustomerAlertMeasurement.compactActionHeight(
                buttonCount: 2,
                layout: layout,
                rowHeights: rowHeights,
                sectionInsets: insets,
                verticalSpacing: 8
            ),
            (rowHeights.max() ?? 0) + 28,
            accuracy: 0.001
        )
    }

    func testCustomerAlertMeasurementSwitchesLongActionsToVertical() {
        let layout = PTCustomerAlertMeasurement.compactActionLayout(
            buttons: ["Cancel", "A very long action title that needs multiple lines"],
            width: 260,
            sectionInsets: .init(top: 10, left: 18, bottom: 18, right: 18),
            horizontalSpacing: 12,
            titleHorizontalInsets: 16,
            font: .systemFont(ofSize: 17),
            isAccessibilityCategory: false
        )

        XCTAssertEqual(layout, .vertical)
    }

    func testCustomerAlertMeasurementAddsVerticalInsetsOnceForScrollableActions() {
        let rowHeights = PTCustomerAlertMeasurement.buttonRowHeights(
            buttons: ["One", "Two", "Three"],
            width: 340,
            layout: .vertical,
            sectionInsets: .init(top: 10, left: 18, bottom: 18, right: 18),
            horizontalSpacing: 12,
            titleHorizontalInsets: 16,
            minimumButtonRowHeight: 50,
            font: .systemFont(ofSize: 15)
        )

        XCTAssertEqual(
            PTCustomerAlertMeasurement.actionsContentHeight(
                rowHeights: rowHeights,
                sectionInsets: .init(top: 10, left: 18, bottom: 18, right: 18),
                verticalSpacing: 8
            ),
            rowHeights.reduce(0, +) + 16 + 28,
            accuracy: 0.001
        )
    }
}
