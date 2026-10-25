import Foundation
import XCTest
@testable import PToolsDebugStudioBridge
import PooToolsDEBUG

private actor StudioRecordingTransport: PTStudioTransport {
    private var received: [PTStudioEnvelope] = []
    private var closed = false

    func send(_ events: [PTStudioEnvelope]) async throws -> PTStudioAcknowledgement {
        received.append(contentsOf: events)
        guard let last = events.last else { throw PTStudioBridgeError.transportRejected }
        return PTStudioAcknowledgement(sessionID: last.sessionID, acceptedSequence: last.sequence)
    }

    func close() { closed = true }
    func allEvents() -> [PTStudioEnvelope] { received }
    func isClosed() -> Bool { closed }
}

final class PTStudioBridgeTests: XCTestCase {
    func testPrivacyGateRedactsSecretsAndNeverSendsBodyFileURLs() throws {
        let gate = PTStudioPrivacyGate(maximumPreviewBytes: 4096)
        let body = Data(#"{"password":"raw-secret","nested":{"token":"raw-secret"},"safe":true}"#.utf8)
        let request = PTNetworkRequestSnapshot(
            url: URL(string: "https://bob:password@example.org/private/123?token=raw-secret&unknown=raw-secret#raw-secret")!,
            method: "POST",
            headers: ["Authorization": "Bearer raw-secret", "Content-Type": "application/json"],
            body: .complete(data: body, totalBytes: Int64(body.count)))
        let response = PTNetworkCaptureResponseSnapshot(
            statusCode: 201,
            headers: ["Set-Cookie": "raw-secret"],
            mimeType: "text/plain",
            body: .file(url: URL(fileURLWithPath: "/private/credentials/raw-secret"),
                        preview: Data("raw-secret".utf8), totalBytes: 100))
        let record = PTNetworkCaptureRecord(request: request, response: response,
                                            timing: PTNetworkTiming(startedAt: .now),
                                            source: .urlProtocol)
        let snapshot = gate.map(record)
        let wire = String(data: try JSONEncoder().encode(snapshot), encoding: .utf8)!
        XCTAssertFalse(wire.contains("raw-secret"))
        XCTAssertFalse(wire.contains("/private/credentials"))
        XCTAssertFalse(wire.contains("/private/123"))
        XCTAssertFalse(wire.contains("bob:password"))
        XCTAssertEqual(snapshot.requestBody.preview?.contains("[REDACTED]"), true)
        XCTAssertNil(snapshot.responseBody?.preview)
        XCTAssertEqual(snapshot.status, 201)
    }

    func testNonJSONAndTruncatedJSONAreFailClosed() {
        let gate = PTStudioPrivacyGate(maximumPreviewBytes: 32)
        let plain = gate.safeBody(.complete(data: Data("bearer-secret".utf8), totalBytes: 13),
                                  mimeType: "text/plain")
        XCTAssertNil(plain.preview)
        let partial = gate.safeBody(.truncated(preview: Data(#"{"token":"secret""#.utf8),
                                              capturedBytes: 17, totalBytes: 100),
                                    mimeType: "application/json")
        XCTAssertNil(partial.preview)
        XCTAssertTrue(partial.truncated)
    }

    func testWireVersionAndCapabilitiesAreExplicit() throws {
        let record = PTStudioEnvelope(sessionID: UUID(), deviceID: UUID(), requestID: nil,
                                      sequence: 1, monotonicTime: 12, source: "ptoolsDebugNetwork",
                                      kind: .capabilities,
                                      payload: PTStudioPayload(capabilities: .current))
        let decoded = try JSONDecoder().decode(PTStudioEnvelope.self, from: JSONEncoder().encode(record))
        XCTAssertEqual(decoded, record)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.payload.capabilities?.observeWebSocketMessages, .notSupported)
        XCTAssertEqual(decoded.payload.capabilities?.supportsBackgroundSession, .notSupported)
    }

    func testPairedTransportRequiresHTTPSAndValidPin() throws {
        XCTAssertThrowsError(try PTStudioPairingCredentials(bearerToken: "weak", leafCertificateSHA256: Data()))
        let credentials = try PTStudioPairingCredentials(bearerToken: String(repeating: "t", count: 32),
                                                         leafCertificateSHA256: Data(repeating: 1, count: 32))
        XCTAssertThrowsError(try PTStudioHTTPSPushTransport(endpoint: URL(string: "http://localhost:9999/ingest")!,
                                                              credentials: credentials))
    }

    func testChangeStreamUpsertFinalizeACKAndOptOut() async throws {
        #if DEBUG
        let store = PTNetworkCaptureStore(maxRecords: 10)
        let bridge = PTStudioBridge(store: store)
        let transport = StudioRecordingTransport()
        let initialStatus = await bridge.status()
        XCTAssertFalse(initialStatus.isRunning)
        try await bridge.start(using: transport,
                               configuration: .init(isEnabled: true, batchInterval: .milliseconds(10)))
        let record = PTNetworkCaptureRecord(
            request: PTNetworkRequestSnapshot(url: URL(string: "https://example.org/users?id=3")!),
            timing: PTNetworkTiming(startedAt: .now), source: .urlProtocol)
        _ = await store.insert(record)
        let didFinalize = await store.finalize(id: record.id, response: nil,
                                               timing: PTNetworkTiming(startedAt: record.timing.startedAt, endedAt: .now),
                                               metrics: nil, error: nil, completion: .completed)
        XCTAssertTrue(didFinalize)
        try await Task.sleep(for: .milliseconds(300))
        let events = await transport.allEvents()
        XCTAssertTrue(events.contains { $0.kind == .hello })
        XCTAssertTrue(events.contains { $0.kind == .capabilities })
        XCTAssertEqual(events.filter { $0.kind == .recordFinalize && $0.requestID == record.id }.count, 1)
        let postSendStatus = await bridge.status()
        XCTAssertEqual(postSendStatus.queuedEvents, 0)
        await bridge.stop()
        let closed = await transport.isClosed()
        XCTAssertTrue(closed)
        let stoppedStatus = await bridge.status()
        XCTAssertFalse(stoppedStatus.isRunning)
        #else
        let bridge = PTStudioBridge(store: PTNetworkCaptureStore())
        do {
            try await bridge.start(using: StudioRecordingTransport(), configuration: .init(isEnabled: true))
            XCTFail("Release must not enable Studio capture")
        } catch PTStudioBridgeError.disabledInRelease {}
        #endif
    }

    func testStopLeavesNoPersistentObserver() async throws {
        #if DEBUG
        let store = PTNetworkCaptureStore()
        let bridge = PTStudioBridge(store: store)
        try await bridge.start(using: StudioRecordingTransport(),
                               configuration: .init(isEnabled: true))
        await bridge.stop()
        try await Task.sleep(for: .milliseconds(100))
        let subscriberCount = await store.activeChangeSubscriberCount()
        XCTAssertEqual(subscriberCount, 0)
        #endif
    }
}
