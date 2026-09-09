import XCTest
@testable import ptools

@MainActor
final class PTPermissionQualityTests: XCTestCase {
    func testPermissionStatusDescriptionsRemainStable() {
        XCTAssertEqual(PTPermission.Status.authorized.description, "authorized")
        XCTAssertEqual(PTPermission.Status.denied.description, "denied")
        XCTAssertEqual(PTPermission.Status.notDetermined.description, "not determined")
        XCTAssertEqual(PTPermission.Status.notSupported.description, "not supported")
    }

    func testPermissionKindNamesRemainStable() {
        XCTAssertEqual(PTPermission.Kind.camera.name, "Camera")
        XCTAssertEqual(PTPermission.Kind.photoLibrary.name, "Photo Library")
        XCTAssertEqual(PTPermission.Kind.location(access: .whenInUse).name, "Location When Use")
        XCTAssertEqual(PTPermission.Kind.location(access: .always).name, "Location Always")
    }
}
