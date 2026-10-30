import XCTest
@testable import PooToolsDEBUG

@MainActor
final class PTDebugHookOwnerLifecycleTests: XCTestCase {
    func testHookRegistryOwnerSurvivesOtherSceneAndReleasesFinalMetadata() {
        let store = PTDebugHookRegistryStore.shared
        let hookID = "unit-" + UUID().uuidString
        let one = store.register(owner: "scene-a", kind: "network", activation: "opt-in", hookID: hookID)
        XCTAssertEqual(one.ownerCount, 1)
        let two = store.register(owner: "scene-b", kind: "network", activation: "opt-in", hookID: hookID)
        XCTAssertEqual(two.ownerCount, 2)
        XCTAssertEqual(store.unregister(owner: "scene-a", hookID: hookID)?.ownerCount, 1)
        XCTAssertTrue(store.entries().contains { $0.owner == hookID })
        XCTAssertNil(store.unregister(owner: "scene-b", hookID: hookID))
        XCTAssertFalse(store.entries().contains { $0.owner == hookID })
        XCTAssertNil(store.unregister(owner: "missing", hookID: hookID))
    }
}
