import XCTest
@testable import ptools

@MainActor
final class PTUIFoundationContractTests: XCTestCase {
    func testSkeletonConfigurationUsesSafeDefaults() {
        let configuration = PTCollectionViewConfig()

        XCTAssertEqual(configuration.skeletonItemCount, 6)
        XCTAssertEqual(configuration.skeletonCornerRadius, 8)
    }

    func testSkeletonConfigurationAcceptsBoundedCustomValues() {
        let configuration = PTCollectionViewConfig()
        configuration.skeletonItemCount = 12
        configuration.skeletonCornerRadius = 14

        XCTAssertEqual(configuration.skeletonItemCount, 12)
        XCTAssertEqual(configuration.skeletonCornerRadius, 14)
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
            max(rowHeights) + 28,
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
