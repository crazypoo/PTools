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
            context: PTAdaptiveBarLayoutContext(bounds: CGRect(x: 0, y: 0, width: 390, height: 844), safeAreaInsets: .zero),
            configuration: .init(presentationPolicy: .legacyClassic),
            navigationActionCount: 1,
            tabItemIDs: tabIDs,
            selectedTabID: "home"
        )

        XCTAssertEqual(geometry.axis, PTAdaptiveBarAxis.horizontalClassic)
        XCTAssertEqual(geometry.renderer, PTAdaptiveBarRenderer.legacyClassic)
        XCTAssertEqual(geometry.visibleTabItemIDs, tabIDs)
    }

    func testMinimizeAndHiddenTransformUsesCorrectAxis() {
        let vertical = PTAdaptiveBarLayoutResolver.resolve(context: context(),
                                                           configuration: .init(),
                                                           navigationActionCount: 1,
                                                           tabItemIDs: tabIDs,
                                                           selectedTabID: "home")
        let classic = PTAdaptiveBarLayoutResolver.resolve(context: PTAdaptiveBarLayoutContext(bounds: CGRect(x: 0, y: 0, width: 390, height: 844), safeAreaInsets: .zero),
                                                          configuration: .init(presentationPolicy: .legacyClassic),
                                                          navigationActionCount: 1,
                                                          tabItemIDs: tabIDs,
                                                          selectedTabID: "home")

        XCTAssertNotEqual(vertical.axis, classic.axis)
        XCTAssertGreaterThan(vertical.customRailRect.height, vertical.customRailRect.width)
        XCTAssertGreaterThan(classic.tabItemsRect.width, classic.tabItemsRect.height)
    }

    func testVisibleRegionMovesControlsAwayFromActiveOcclusion() {
        let occlusion = PTAdaptiveReservedRegion(frame: CGRect(x: 320, y: 0, width: 70, height: 844),
                                                  margins: .zero,
                                                  kind: .occlusion,
                                                  isActive: true)
        let region = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                          insets: UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0),
                          regions: [occlusion]),
            minimumMargin: 4
        )
        let frame = PTAdaptiveVisibleRegionResolver.controlFrame(size: CGSize(width: 80, height: 44),
                                                                  in: region,
                                                                  preferred: .trailing,
                                                                  margin: 4)

        // English: The visible pane itself must exclude the active Duo occlusion, not only the final control frame.
        // Español: El panel visible también debe excluir la oclusión Duo activa, no solo el frame final del control.
        // 中文：可视面板本身必须排除 Duo 遮挡区，而不只是让最终控件 Frame 避开它。
        XCTAssertEqual(region.visibleRect.maxX, 320)
        XCTAssertFalse(frame.intersects(occlusion.frame))
        XCTAssertGreaterThanOrEqual(frame.minX, 4)
        XCTAssertLessThanOrEqual(frame.maxX, 320)
    }

    func testVisibleRegionUsesLargestPaneAcrossDivision() {
        let division = PTAdaptiveReservedRegion(frame: CGRect(x: 0, y: 400, width: 390, height: 44),
                                                  kind: .division,
                                                  isActive: true)
        let region = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                          regions: [division])
        )

        XCTAssertEqual(region.visibleRect.minY, 0)
        XCTAssertEqual(region.visibleRect.maxY, 400)
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
            context: PTAdaptiveBarLayoutContext(bounds: CGRect(x: 0, y: 0, width: 390, height: 844), safeAreaInsets: .zero),
            configuration: .init(),
            navigationActionCount: 1,
            tabItemIDs: tabIDs,
            selectedTabID: "home"
        )

        XCTAssertEqual(geometry.axis, PTAdaptiveBarAxis.horizontalClassic)
        XCTAssertEqual(geometry.renderer, PTAdaptiveBarRenderer.legacyClassic)
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

    func testVisiblePanesExcludeEveryActiveReservedRegion() {
        let regions = [
            PTAdaptiveReservedRegion(frame: CGRect(x: 180, y: 0, width: 20, height: 844),
                                     kind: .division,
                                     isActive: true),
            PTAdaptiveReservedRegion(frame: CGRect(x: 0, y: 300, width: 180, height: 60),
                                     kind: .occlusion,
                                     isActive: true)
        ]
        let region = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 844), regions: regions)
        )

        XCTAssertFalse(region.availablePanes.isEmpty)
        for pane in region.availablePanes {
            XCTAssertFalse(pane.intersects(regions[0].frame))
            XCTAssertFalse(pane.intersects(regions[1].frame))
        }
    }

    func testNoInteractiveFrameOverlapsReservedRegion() {
        let reserved = PTAdaptiveReservedRegion(frame: CGRect(x: 180, y: 0, width: 20, height: 844),
                                                 kind: .division,
                                                 isActive: true)
        let region = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 844), regions: [reserved])
        )
        let frame = PTAdaptiveVisibleRegionResolver.controlFrame(size: CGSize(width: 80, height: 44),
                                                                 in: region,
                                                                 preferred: .trailing)

        XCTAssertFalse(frame.intersects(reserved.frame))
    }

    func testVerticalRailNavTabAccessoryOverflowNoCollision() {
        let geometry = PTAdaptiveBarLayoutResolver.resolve(context: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 300)),
                                                            configuration: .init(),
                                                            navigationActionCount: 2,
                                                            tabItemIDs: (0..<20).map(String.init),
                                                            selectedTabID: "17",
                                                            accessoryHeight: 44)

        XCTAssertFalse(geometry.navItemsRect.intersects(geometry.tabItemsRect))
        XCTAssertFalse(geometry.navItemsRect.intersects(geometry.accessoryRect))
        XCTAssertFalse(geometry.tabItemsRect.intersects(geometry.accessoryRect))
        XCTAssertTrue(geometry.visibleTabItemIDs.contains("17"))
        XCTAssertTrue(geometry.overflowTabItemIDs.contains("0"))
    }

    func testLayoutSignatureChangesOnlyWithGeometry() {
        let first = PTAdaptiveVisibleRegionResolver.region(for: context())
        let second = PTAdaptiveVisibleRegionResolver.region(for: context())
        let resized = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 720, height: 520))
        )

        XCTAssertEqual(first.signature, second.signature)
        XCTAssertNotEqual(first.signature, resized.signature)
    }

    func testNoInfiniteLayoutInvalidationOnResize() {
        let hostView = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        hostView.overrideUserInterfaceStyle = .light
        let coordinator = PTAdaptiveBarCoordinator(hostView: hostView)

        _ = coordinator.update(navigationActionCount: 1,
                               tabItemIDs: tabIDs,
                               selectedTabID: "home")
        let firstGeneration = coordinator.generation
        _ = coordinator.update(navigationActionCount: 1,
                               tabItemIDs: tabIDs,
                               selectedTabID: "home")

        XCTAssertEqual(coordinator.generation, firstGeneration)
        hostView.frame.size = CGSize(width: 720, height: 520)
        _ = coordinator.update(navigationActionCount: 1,
                               tabItemIDs: tabIDs,
                               selectedTabID: "home")
        XCTAssertEqual(coordinator.generation, firstGeneration + 1)
    }

    func testPhotoGridItemFramesStayWithinUsablePanes() {
        let division = PTAdaptiveReservedRegion(frame: CGRect(x: 390, y: 0, width: 20, height: 520),
                                                 kind: .division,
                                                 isActive: true)
        let region = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 800, height: 520), regions: [division])
        )
        let item = CGRect(x: region.visibleRect.minX + 8,
                          y: region.visibleRect.minY + 8,
                          width: min(120, region.visibleRect.width - 16),
                          height: 120)

        XCTAssertTrue(region.visibleRect.contains(item))
        XCTAssertFalse(region.reservedRects.contains { $0.intersects(item) })
    }

    func testPagingFourMediaAfterResizePreservesItemIdentity() {
        let mediaIDs = ["one", "two", "three", "four"]
        let before = PTAdaptiveBarLayoutResolver.resolve(context: context(),
                                                         configuration: .init(),
                                                         navigationActionCount: 1,
                                                         tabItemIDs: mediaIDs,
                                                         selectedTabID: "three")
        let after = PTAdaptiveBarLayoutResolver.resolve(context: context(bounds: CGRect(x: 0, y: 0, width: 720, height: 520)),
                                                        configuration: .init(),
                                                        navigationActionCount: 1,
                                                        tabItemIDs: mediaIDs,
                                                        selectedTabID: "three")

        XCTAssertTrue(before.visibleTabItemIDs.contains("three"))
        XCTAssertTrue(after.visibleTabItemIDs.contains("three"))
        XCTAssertEqual(mediaIDs, ["one", "two", "three", "four"])
    }

    func testEditorCropCoordinatesAfterResize() {
        let crop = CGRect(x: 40, y: 60, width: 200, height: 160)
        let oldBounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        let newBounds = CGRect(x: 0, y: 0, width: 720, height: 520)
        let scale = min(newBounds.width / oldBounds.width, newBounds.height / oldBounds.height)
        let resized = CGRect(x: crop.minX * scale,
                             y: crop.minY * scale,
                             width: crop.width * scale,
                             height: crop.height * scale)

        XCTAssertTrue(newBounds.contains(resized))
        XCTAssertEqual(resized.width / scale, crop.width, accuracy: 0.0001)
        XCTAssertEqual(resized.height / scale, crop.height, accuracy: 0.0001)
    }

    func testKeyboardFormFooterAndPopoverAvoidOcclusion() {
        let keyboard = PTAdaptiveReservedRegion(frame: CGRect(x: 0, y: 600, width: 390, height: 244),
                                                 kind: .occlusion,
                                                 isActive: true)
        let region = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 844), regions: [keyboard])
        )
        let footer = PTAdaptiveVisibleRegionResolver.controlFrame(size: CGSize(width: 200, height: 44),
                                                                  in: region,
                                                                  preferred: .trailing)

        XCTAssertFalse(footer.intersects(keyboard.frame))
        XCTAssertLessThanOrEqual(footer.maxY, keyboard.frame.minY)
    }

    func testSplitViewCollapseExpandRetainsSelection() {
        let selected = "detail"
        let expanded = PTAdaptiveBarLayoutResolver.resolve(context: context(bounds: CGRect(x: 0, y: 0, width: 820, height: 600)),
                                                           configuration: .init(),
                                                           navigationActionCount: 1,
                                                           tabItemIDs: ["master", selected],
                                                           selectedTabID: selected)
        let collapsed = PTAdaptiveBarLayoutResolver.resolve(context: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 844)),
                                                            configuration: .init(),
                                                            navigationActionCount: 1,
                                                            tabItemIDs: ["master", selected],
                                                            selectedTabID: selected)

        XCTAssertTrue(expanded.visibleTabItemIDs.contains(selected))
        XCTAssertTrue(collapsed.visibleTabItemIDs.contains(selected))
    }

    func testRTLVerticalEdgeFollowsSystem() {
        let rtl = PTAdaptiveBarLayoutContext(bounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                                             safeAreaInsets: .zero,
                                             verticalBarEdge: .trailing,
                                             layoutDirection: .rightToLeft)
        let geometry = PTAdaptiveBarLayoutResolver.resolve(context: rtl,
                                                            configuration: .init(),
                                                            navigationActionCount: 1,
                                                            tabItemIDs: tabIDs,
                                                            selectedTabID: "home")

        XCTAssertEqual(geometry.edge, .trailing)
        XCTAssertGreaterThan(geometry.customRailRect.minX, 0)
    }

    func testMultiSceneDoesNotReuseStaleGeometry() {
        let firstScene = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                          insets: UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0))
        )
        let secondScene = PTAdaptiveVisibleRegionResolver.region(
            for: context(bounds: CGRect(x: 0, y: 0, width: 820, height: 600),
                          insets: UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 40))
        )

        XCTAssertNotEqual(firstScene.signature, secondScene.signature)
        XCTAssertNotEqual(firstScene.visibleRect, secondScene.visibleRect)
    }
}
