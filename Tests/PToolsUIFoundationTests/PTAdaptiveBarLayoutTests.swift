import UIKit
import XCTest
@testable import ptools

// English: Validate adaptive bar geometry with injectable values instead of a physical Duo device.
// Español: Valida la geometría adaptativa con valores inyectables en lugar de un dispositivo Duo físico.
// 中文：使用可注入值验证自适应 Bar 几何，不依赖真实 Duo 设备。
@MainActor
final class PTAdaptiveBarLayoutTests: XCTestCase {
    private let tabIDs = ["home", "list", "profile", "settings", "help"]

    private func context(edge: PTAdaptiveBarEdge = .leading,
                         bounds: CGRect = CGRect(x: 0, y: 0, width: 390, height: 844),
                         insets: UIEdgeInsets = .zero,
                         regions: [PTAdaptiveReservedRegion] = []) -> PTAdaptiveBarLayoutContext {
        PTAdaptiveBarLayoutContext(bounds: bounds,
                                   safeAreaInsets: insets,
                                   verticalBarEdge: edge,
                                   reservedRegions: regions)
    }

    func testVerticalNavAndTabsNeverOverlap() {
        let geometry = PTAdaptiveBarLayoutResolver.resolve(context: context(),
                                                            configuration: .init(),
                                                            navigationActionCount: 2,
                                                            tabItemIDs: tabIDs,
                                                            selectedTabID: "list")

        XCTAssertEqual(geometry.axis, .verticalEdge)
        XCTAssertFalse(geometry.navItemsRect.intersects(geometry.tabItemsRect))
        XCTAssertFalse(geometry.navItemsRect.intersects(geometry.accessoryRect))
        XCTAssertFalse(geometry.tabItemsRect.intersects(geometry.accessoryRect))
    }

    func testVerticalRailAvoidsOcclusionAndDivision() {
        let region = PTAdaptiveReservedRegion(frame: CGRect(x: 0, y: 250, width: 390, height: 12),
                                               kind: .division,
                                               isActive: true)
        let geometry = PTAdaptiveBarLayoutResolver.resolve(context: context(regions: [region]),
                                                            configuration: .init(),
                                                            navigationActionCount: 1,
                                                            tabItemIDs: tabIDs,
                                                            selectedTabID: "home")

        XCTAssertFalse(geometry.customRailRect.intersects(region.frame))
    }

    func testVerticalBarEdgeLeadingAndTrailing() {
        let leading = PTAdaptiveBarLayoutResolver.resolve(context: context(edge: .leading),
                                                           configuration: .init(),
                                                           navigationActionCount: 1,
                                                           tabItemIDs: tabIDs,
                                                           selectedTabID: "home")
        let trailing = PTAdaptiveBarLayoutResolver.resolve(context: context(edge: .trailing),
                                                           configuration: .init(),
                                                           navigationActionCount: 1,
                                                           tabItemIDs: tabIDs,
                                                           selectedTabID: "home")

        XCTAssertLessThan(leading.customRailRect.minX, trailing.customRailRect.minX)
        XCTAssertEqual(leading.edge, .leading)
        XCTAssertEqual(trailing.edge, .trailing)
    }

    func testAsymmetricSafeAreaIsNotDoubleApplied() {
        let geometry = PTAdaptiveBarLayoutResolver.resolve(
            context: context(insets: UIEdgeInsets(top: 30, left: 17, bottom: 23, right: 9)),
            configuration: .init(),
            navigationActionCount: 1,
            tabItemIDs: tabIDs,
            selectedTabID: "home"
        )

        XCTAssertEqual(geometry.contentSafeRect.minX, 17)
        XCTAssertEqual(geometry.contentSafeRect.maxX, 381)
        XCTAssertEqual(geometry.contentSafeRect.minY, 30)
        XCTAssertEqual(geometry.contentSafeRect.maxY, 821)
    }

    func testOverflowPreservesBackAndSelectedTab() {
        let manyTabs = (0..<40).map(String.init)
        let geometry = PTAdaptiveBarLayoutResolver.resolve(context: context(bounds: CGRect(x: 0, y: 0, width: 160, height: 180)),
                                                            configuration: .init(),
                                                            navigationActionCount: 2,
                                                            tabItemIDs: manyTabs,
                                                            selectedTabID: "27")

        XCTAssertTrue(geometry.visibleTabItemIDs.contains("27"))
        XCTAssertFalse(geometry.overflowTabItemIDs.contains("27"))
        XCTAssertFalse(geometry.overflowTabItemIDs.isEmpty)
    }

    func testSystemCustomRendererSingleOwnership() {
        let system = PTAdaptiveBarLayoutResolver.resolve(context: context(),
                                                         configuration: .init(presentationPolicy: .preferSystemAdaptive),
                                                         navigationActionCount: 1,
                                                         tabItemIDs: tabIDs,
                                                         selectedTabID: "home")
        let custom = PTAdaptiveBarLayoutResolver.resolve(context: context(),
                                                         configuration: .init(presentationPolicy: .customAdaptive),
                                                         navigationActionCount: 1,
                                                         tabItemIDs: tabIDs,
                                                         selectedTabID: "home")

        XCTAssertNotEqual(system.renderer, custom.renderer)
        XCTAssertEqual(system.renderer, .systemAdaptive)
        XCTAssertEqual(custom.renderer, .customAdaptive)
    }

    func testFoldResizingPreservesSelectionAndNavigation() {
        let first = PTAdaptiveBarLayoutResolver.resolve(context: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 844)),
                                                        configuration: .init(),
                                                        navigationActionCount: 2,
                                                        tabItemIDs: tabIDs,
                                                        selectedTabID: "profile")
        let second = PTAdaptiveBarLayoutResolver.resolve(context: context(bounds: CGRect(x: 0, y: 0, width: 720, height: 520)),
                                                         configuration: .init(),
                                                         navigationActionCount: 2,
                                                         tabItemIDs: tabIDs,
                                                         selectedTabID: "profile")

        XCTAssertTrue(first.visibleTabItemIDs.contains("profile"))
        XCTAssertTrue(second.visibleTabItemIDs.contains("profile"))
        XCTAssertEqual(first.visibleTabItemIDs.count, second.visibleTabItemIDs.count)
    }

    func testClassicAppearanceAndItemInsetsUnchanged() {
        let geometry = PTAdaptiveBarLayoutResolver.resolve(
            context: PTAdaptiveBarLayoutContext(bounds: CGRect(x: 0, y: 0, width: 390, height: 844)),
            configuration: .init(presentationPolicy: .legacyClassic),
            navigationActionCount: 1,
            tabItemIDs: tabIDs,
            selectedTabID: "home"
        )

        XCTAssertEqual(geometry.axis, .horizontalClassic)
        XCTAssertEqual(geometry.renderer, .legacyClassic)
        XCTAssertEqual(geometry.visibleTabItemIDs, tabIDs)
    }

    func testMinimizeAndHiddenTransformUsesCorrectAxis() {
        let vertical = PTAdaptiveBarLayoutResolver.resolve(context: context(),
                                                           configuration: .init(),
                                                           navigationActionCount: 1,
                                                           tabItemIDs: tabIDs,
                                                           selectedTabID: "home")
        let classic = PTAdaptiveBarLayoutResolver.resolve(context: PTAdaptiveBarLayoutContext(bounds: CGRect(x: 0, y: 0, width: 390, height: 844)),
                                                          configuration: .init(presentationPolicy: .legacyClassic),
                                                          navigationActionCount: 1,
                                                          tabItemIDs: tabIDs,
                                                          selectedTabID: "home")

        XCTAssertNotEqual(vertical.axis, classic.axis)
        XCTAssertGreaterThan(vertical.customRailRect.height, vertical.customRailRect.width)
        XCTAssertGreaterThan(classic.tabItemsRect.width, classic.tabItemsRect.height)
    }

    func testAccessoryDoesNotBlockScrollOrInput() {
        let geometry = PTAdaptiveBarLayoutResolver.resolve(context: context(),
                                                            configuration: .init(),
                                                            navigationActionCount: 1,
                                                            tabItemIDs: tabIDs,
                                                            selectedTabID: "home",
                                                            accessoryHeight: 36)

        XCTAssertFalse(geometry.accessoryRect.isEmpty)
        XCTAssertFalse(geometry.accessoryRect.intersects(geometry.tabItemsRect))
        XCTAssertFalse(geometry.accessoryRect.intersects(geometry.navItemsRect))
    }

    func testNonDuoIOS17UsesClassicRenderer() {
        let geometry = PTAdaptiveBarLayoutResolver.resolve(
            context: PTAdaptiveBarLayoutContext(bounds: CGRect(x: 0, y: 0, width: 390, height: 844)),
            configuration: .init(),
            navigationActionCount: 1,
            tabItemIDs: tabIDs,
            selectedTabID: "home"
        )

        XCTAssertEqual(geometry.axis, .horizontalClassic)
        XCTAssertEqual(geometry.renderer, .legacyClassic)
    }

    func testMultiSceneStateDoesNotLeak() {
        let leading = PTAdaptiveBarLayoutResolver.resolve(context: context(edge: .leading),
                                                           configuration: .init(),
                                                           navigationActionCount: 1,
                                                           tabItemIDs: tabIDs,
                                                           selectedTabID: "home")
        let trailing = PTAdaptiveBarLayoutResolver.resolve(context: context(edge: .trailing),
                                                           configuration: .init(),
                                                           navigationActionCount: 1,
                                                           tabItemIDs: tabIDs,
                                                           selectedTabID: "settings")

        XCTAssertEqual(leading.edge, .leading)
        XCTAssertEqual(trailing.edge, .trailing)
        XCTAssertTrue(leading.visibleTabItemIDs.contains("home"))
        XCTAssertTrue(trailing.visibleTabItemIDs.contains("settings"))
    }
}
