import XCTest
import PToolsDebugConsoleCore

@MainActor
final class PTDebugConsoleCoreTests: XCTestCase {
    func testObserverTokenRemovalDoesNotAffectOtherConsumers() {
        let center = PTDebugEventCenter.shared
        let identifier = UUID().uuidString
        var first: [String] = []
        var second: [String] = []
        let a = center.addObserver { if $0.source == identifier { first.append($0.name) } }
        let b = center.addObserver { if $0.source == identifier { second.append($0.name) } }
        center.publish(PTDebugEvent(name: "initial", source: identifier))
        center.removeObserver(a)
        center.publish(PTDebugEvent(name: "next", source: identifier))
        center.removeObserver(b)
        XCTAssertEqual(first, ["initial"])
        XCTAssertEqual(second, ["initial", "next"])
    }
}
