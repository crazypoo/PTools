// English: Contract tests for native UIControl menus and selection rendering.
// Español: Pruebas de contrato para menús nativos de UIControl y renderizado de selección.
// 中文：覆盖 UIControl 原生菜单和选择态渲染契约的测试。

import XCTest
import UIKit
@testable import ptools

@MainActor
final class PTControlMenuTests: XCTestCase {
    private enum Sort: String, Hashable {
        case all
        case price
    }

    func testUIButtonUsesNativeMenuAndRestoresPreviousState() {
        let button = UIButton(type: .system)
        let originalMenu = UIMenu(title: "Original", children: [])
        button.menu = originalMenu
        button.showsMenuAsPrimaryAction = false

        let installedMenu = UIMenu(title: "Installed", children: [UIAction(title: "Action") { _ in }])
        button.pt_setMenu(installedMenu, trigger: .primaryAction)

        XCTAssertTrue(button.menu === installedMenu)
        XCTAssertTrue(button.showsMenuAsPrimaryAction)

        button.pt_removeMenu()

        XCTAssertTrue(button.menu === originalMenu)
        XCTAssertFalse(button.showsMenuAsPrimaryAction)
    }

    func testActionLayoutButtonUsesUIKitControlMenuLifecycle() {
        let button = PTActionLayoutButton(frame: .zero)
        button.pt_setMenu(UIMenu(children: [UIAction(title: "Action") { _ in }]), trigger: .primaryAction)

        XCTAssertTrue(button.isContextMenuInteractionEnabled)
        XCTAssertTrue(button.showsMenuAsPrimaryAction)
        XCTAssertNotNil(button.contextMenuInteraction)

        button.pt_removeMenu()

        XCTAssertFalse(button.isContextMenuInteractionEnabled)
        XCTAssertFalse(button.showsMenuAsPrimaryAction)
    }

    func testPlainUIControlGetsLongPressBridgeWithoutChangingNativeFlags() {
        let control = UIControl(frame: .zero)
        control.pt_setMenu(UIMenu(children: [UIAction(title: "Action") { _ in }]), trigger: .longPress)

        XCTAssertFalse(control.isContextMenuInteractionEnabled)
        XCTAssertNotNil(control.interactions.first { $0 is UIContextMenuInteraction })

        control.pt_removeMenu()

        XCTAssertNil(control.interactions.first { $0 is UIContextMenuInteraction })
    }

    func testPlainUIControlDoesNotFakePrimaryActionMenu() {
        let control = UIControl(frame: .zero)
        control.pt_setMenu(UIMenu(children: [UIAction(title: "Action") { _ in }]), trigger: .primaryAction)

        XCTAssertNil(control.interactions.first { $0 is UIContextMenuInteraction })
    }

    func testSelectionMenuUsesOnlySelectedImage() {
        let menu = PTControlMenuFactory.makeSelectionMenu(
            items: [
                PTControlMenuSelectionItem(id: Sort.all, title: "All"),
                PTControlMenuSelectionItem(id: Sort.price, title: "Price", selectedImage: UIImage(systemName: "dollarsign.circle"))
            ],
            selectedID: Sort.price,
            selectionChanged: { _ in }
        )

        let actions = menu?.children.compactMap { $0 as? UIAction } ?? []
        XCTAssertNil(actions.first { $0.title == "All" }?.image)
        XCTAssertNotNil(actions.first { $0.title == "Price" }?.image)
    }

    func testSelectionMenuDefaultsToCheckmark() {
        let menu = PTControlMenuFactory.makeSelectionMenu(
            items: [PTControlMenuSelectionItem(id: Sort.all, title: "All")],
            selectedID: Sort.all,
            selectionChanged: { _ in }
        )

        let action = menu?.children.first as? UIAction
        XCTAssertNotNil(action?.image)
    }

    func testLoadingDisablesMenuThroughExistingInteractionState() {
        let button = PTActionLayoutButton(frame: .zero)
        button.pt_setMenu(UIMenu(children: [UIAction(title: "Action") { _ in }]), trigger: .longPress)

        button.startLoading()
        XCTAssertFalse(button.isUserInteractionEnabled)
        button.stopLoading()
        XCTAssertTrue(button.isUserInteractionEnabled)
        XCTAssertNotNil(button.contextMenuInteraction)
    }
}
