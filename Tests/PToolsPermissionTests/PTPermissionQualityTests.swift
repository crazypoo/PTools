import XCTest
import UIKit
import os.lock
import PToolsPermissionCore
@testable import ptools

@MainActor
final class PTPermissionQualityTests: XCTestCase {
    func testPermissionStatusDescriptionsRemainStable() {
        XCTAssertEqual(ptools.PTPermission.Status.authorized.description, "authorized")
        XCTAssertEqual(ptools.PTPermission.Status.denied.description, "denied")
        XCTAssertEqual(ptools.PTPermission.Status.notDetermined.description, "not determined")
        XCTAssertEqual(ptools.PTPermission.Status.notSupported.description, "not supported")
    }

    func testPermissionKindNamesRemainStable() {
        XCTAssertEqual(ptools.PTPermission.Kind.camera.name, "Camera")
        XCTAssertEqual(ptools.PTPermission.Kind.photoLibrary.name, "Photo Library")
        XCTAssertEqual(ptools.PTPermission.Kind.location(access: .whenInUse).name, "Location When Use")
        XCTAssertEqual(ptools.PTPermission.Kind.location(access: .always).name, "Location Always")
    }

    func testSystemSettingsURLResolvesTheAppSettingsAlias() {
        let legacy = PTPermissionSettings.applicationURL
        let expected = URL(string: UIApplication.openSettingsURLString)
        XCTAssertEqual(PTPermissionSettingsRouter.resolvedURL(legacy), expected)
        XCTAssertNil(PTPermissionSettingsRouter.resolvedURL(nil))
        let custom = URL(string: "ptools-settings-test://custom")!
        XCTAssertEqual(PTPermissionSettingsRouter.resolvedURL(custom), custom)
    }

    func testPhotoLibraryAndPluralSettingsMethodsUseTheSharedRouter() {
        let observedURLs = OSAllocatedUnfairLock(initialState: [URL?]())
        PTPermissionSettingsRouter.install { url in
            observedURLs.withLock { $0.append(url) }
        }
        defer { PTPermissionSettingsRouter.uninstall() }

        // Covers the exact public API reported by the app, plus its plural alias.
        ptools.PTPermission.photoLibrary.openSettingPage()
        ptools.PTPermission.photoLibrary.openSettings()
        PTPermissionSettingsRouter.open(URL(string: "ptools-settings-test://custom"))

        let results = observedURLs.withLock { $0 }
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0], PTPermissionSettings.applicationURL)
        XCTAssertEqual(results[1], PTPermissionSettings.applicationURL)
        XCTAssertEqual(results[2], URL(string: "ptools-settings-test://custom"))
    }
}
