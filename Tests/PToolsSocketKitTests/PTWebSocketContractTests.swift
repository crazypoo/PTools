import XCTest
@testable import PooToolsSocketKit

final class PTWebSocketContractTests: XCTestCase {
    func testMessagesAreValueTypes() {
        XCTAssertEqual(PTWebSocketMessage.text("hello"), .text("hello"))
        XCTAssertEqual(PTWebSocketMessage.data(Data([1, 2])), .data(Data([1, 2])))
    }

    func testRejectNewestBufferKeepsFIFO() throws {
        var buffer = PTWebSocketSendBuffer(configuration: .init(capacity: 2, overflowPolicy: .rejectNewest))
        try buffer.enqueue(.text("first"))
        try buffer.enqueue(.text("second"))
        XCTAssertThrowsError(try buffer.enqueue(.text("third")))
        XCTAssertEqual(buffer.snapshot(), [.text("first"), .text("second")])
    }

    func testDropOldestBufferKeepsNewestCapacity() throws {
        var buffer = PTWebSocketSendBuffer(configuration: .init(capacity: 2, overflowPolicy: .dropOldest))
        try buffer.enqueue(.text("first"))
        try buffer.enqueue(.text("second"))
        try buffer.enqueue(.text("third"))
        XCTAssertEqual(buffer.snapshot(), [.text("second"), .text("third")])
    }

    func testLegacyConfigurationBuildsNativePolicies() {
        let configuration = PTWebSocketConfiguration(url: URL(string: "wss://example.com/socket")!,
                                                      maxReconnectAttempts: 3,
                                                      reconnectBaseDelay: 2,
                                                      maxQueuedMessages: 4)
        XCTAssertEqual(configuration.maxReconnectAttempts, 3)
        XCTAssertEqual(configuration.maxQueuedMessages, 4)
        XCTAssertEqual(configuration.sendBuffer.capacity, 4)
        XCTAssertEqual(configuration.reconnectPolicy,
                       .exponential(maxAttempts: 3,
                                    initialDelay: .seconds(2),
                                    multiplier: 2,
                                    maxDelay: .seconds(60),
                                    jitter: 0.2))
    }

    func testStateMachinePublishesExplicitState() {
        var machine = PTWebSocketStateMachine()
        XCTAssertEqual(machine.state, .idle)
        machine.transition(to: .connected)
        XCTAssertEqual(machine.state, .connected)
    }
}
