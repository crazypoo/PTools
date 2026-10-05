import XCTest
@testable import PToolsDatabase
@testable import PToolsDatabaseCore
@testable import PToolsRealtimeCore
@testable import PToolsAuthCore
@testable import PToolsAuth
@testable import PToolsTransferCore
@testable import PToolsTransfer
@testable import PToolsSyncCore
@testable import PToolsSync
@testable import PToolsStoreKit
@testable import PToolsObservabilityCore
@testable import PToolsObservability
@testable import PToolsWebCore
@testable import PToolsWebBridge
@testable import PToolsMapCore
@testable import PToolsMap
@testable import PToolsAppIntegrity
@testable import PToolsConfiguration

final class PTApplicationInfrastructureTests: XCTestCase {
    func testDatabaseBindsValuesAndReadsRows() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ptools-application-infrastructure-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let database = try PTDatabase(fileURL: url)
        try await database.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
        _ = try await database.insert(
            PTDatabaseQuery("INSERT INTO users (name) VALUES (?)", arguments: [.text("Jax")])
        )

        let rows = try await database.query("SELECT id, name FROM users WHERE name = ?", arguments: [.text("Jax")])
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?["name"], .text("Jax"))
    }

    func testMigrationValidatorRejectsGapsAndAcceptsExplicitDestructivePlan() throws {
        XCTAssertThrowsError(try PTDatabaseMigrationValidator.validate([
            PTDatabaseMigration(fromVersion: 0, toVersion: 2, statements: ["CREATE TABLE demo (id INTEGER)"])
        ], currentVersion: 0))

        let validation = try PTDatabaseMigrationValidator.validate([
            PTDatabaseMigration(fromVersion: 0, toVersion: 1, statements: ["CREATE TABLE demo (id INTEGER)"]),
            PTDatabaseMigration(fromVersion: 1, toVersion: 2, statements: ["DROP TABLE demo"], isDestructive: true)
        ], currentVersion: 0)
        XCTAssertEqual(validation.pendingVersions, [1, 2])
    }

    func testDatabasePaginationClampsInputAndUsesLookAhead() async throws {
        let database = try PTDatabase()
        try await database.execute("CREATE TABLE values (id INTEGER PRIMARY KEY)")
        for index in 0..<3 {
            _ = try await database.insert(PTDatabaseQuery("INSERT INTO values (id) VALUES (?)", arguments: [.integer(Int64(index))]))
        }
        let page = try await database.page(PTDatabaseQuery("SELECT id FROM values ORDER BY id"), offset: -2, limit: 2)
        XCTAssertEqual(page.offset, 0)
        XCTAssertEqual(page.limit, 2)
        XCTAssertEqual(page.values.count, 2)
        XCTAssertTrue(page.hasMore)
    }

    func testDatabaseRuntimeSnapshotAndCustomMigration() async throws {
        let database = try PTDatabase()
        let result = try await database.migrate(steps: [
            PTTestMigrationStep(fromVersion: 0, toVersion: 1)
        ])
        XCTAssertEqual(result.appliedVersions, [1])
        XCTAssertEqual(result.finalSchemaVersion, 1)
        let runtime = try await database.runtimeSnapshot()
        XCTAssertEqual(runtime.schemaVersion, 1)
        XCTAssertFalse(runtime.sqliteVersion.isEmpty)
    }

    func testSSEParserCombinesDataLines() {
        var parser = PTSSEParser()
        XCTAssertNil(parser.consume("event: update"))
        XCTAssertNil(parser.consume("id: 7"))
        XCTAssertNil(parser.consume("data: first"))
        XCTAssertNil(parser.consume("data: second"))

        let event = parser.finish()
        XCTAssertEqual(event, PTRealtimeEvent(event: "update", data: "first\nsecond", id: "7"))
    }

    func testSSEParserReadsServerRetryDirective() {
        var parser = PTSSEParser()
        XCTAssertNil(parser.consume("retry: 1500"))
        XCTAssertNil(parser.consume("data: ping"))
        XCTAssertEqual(parser.finish()?.retryAfter, .milliseconds(1500))
    }

    func testPKCEChallengeAndCallbackAreTyped() throws {
        let challenge = PTOAuthPKCE.makeChallenge(state: "state")
        var components = URLComponents(string: "demo://callback")!
        components.queryItems = [URLQueryItem(name: "code", value: "code"),
                                 URLQueryItem(name: "state", value: challenge.state)]
        let callback = try PTOAuthPKCE.validate(callbackURL: components.url!, expectedState: "state")
        XCTAssertEqual(callback.code, "code")
    }

    func testAuthUnauthorizedReplayUsesSingleFlightRefresh() async throws {
        let store = PTTestAuthCredentialStore()
        let remote = PTTestAuthRemoteProvider()
        let service = PTAuthService(credentialStore: store, remoteProvider: remote)
        let expired = PTAuthToken(accessToken: "expired", refreshToken: "refresh", expiresAt: .distantPast)
        try await service.signIn(PTAuthSession(userID: "demo", token: expired))

        let values = try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for _ in 0..<100 {
                group.addTask { try await service.validToken().accessToken }
            }
            var result: [String] = []
            for try await value in group { result.append(value) }
            return result
        }
        XCTAssertEqual(values.count, 100)
        let refreshCount = await remote.refreshCount
        XCTAssertEqual(refreshCount, 1)
    }

    func testTransferSnapshotPreservesPriorityAndState() {
        let request = PTTransferRequest(source: .download(URL(string: "https://example.invalid")!), priority: .high)
        let snapshot = PTTransferSnapshot(request: request, state: .paused)
        XCTAssertEqual(snapshot.request.priority, .high)
        XCTAssertEqual(snapshot.state, .paused)
        XCTAssertEqual(snapshot.request.policy.maxConcurrent, 3)
    }

    func testConfigurationTargetingUsesStableBucket() {
        let context = PTConfigurationContext(environment: .staging,
                                             appVersion: "5.62.0",
                                             buildNumber: "62",
                                             deviceFamily: "iPhone",
                                             locale: "zh-Hans")
        let targeting = PTConfigurationTargeting(environment: .staging,
                                                  minimumAppVersion: "5.0.0",
                                                  minimumBuildNumber: 60,
                                                  locale: "zh-Hans",
                                                  deviceFamily: "iPhone",
                                                  percentage: 100,
                                                  stableIdentifier: "demo")
        XCTAssertTrue(targeting.matches(context))
    }

    func testWebBootstrapHasPromiseAppNamespace() {
        let source = PTWebScriptBootstrap(methods: ["ping"]).source()
        XCTAssertTrue(source.contains("window.App"))
        XCTAssertTrue(source.contains("PToolsBridge"))
    }

    func testObservabilitySpanHandleEndsExactlyOnceAndRedactsText() async {
        let recorder = PTObservabilityRecorder(configuration: PTObservabilityConfiguration(sampleRate: 1))
        let span = await recorder.startSpan(name: "checkout")
        await span.setAttribute("token=secret", for: "message")
        await span.addEvent("request", attributes: ["Authorization": "secret"])
        await span.end()
        await span.end()
        let records = await recorder.snapshot()
        XCTAssertEqual(records.filter { if case .span = $0 { return true }; return false }.count, 1)
        XCTAssertTrue(String(describing: records).contains("[REDACTED]"))
    }

    func testObservabilityPersistentBufferFlushesBoundedRecords() async {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ptools-observability-\(UUID().uuidString).jsonl")
        let buffer = PTPersistentObservabilityBuffer(fileURL: url, maximumRecords: 2)
        let recorder = PTObservabilityRecorder(persistentBuffer: buffer)
        await recorder.record(event: PTObservabilityEvent(name: "one"))
        await recorder.record(event: PTObservabilityEvent(name: "two"))
        await recorder.record(event: PTObservabilityEvent(name: "three"))
        let pendingCount = await buffer.pending().count
        XCTAssertEqual(pendingCount, 2)
        let sink = PTTestObservabilitySink()
        let flushed = await buffer.flush(to: [sink])
        let received = await sink.records.count
        XCTAssertEqual(flushed, 2)
        XCTAssertEqual(received, 2)
        try? FileManager.default.removeItem(at: url)
    }

    func testMapValueTypesRemainSendableContracts() {
        let coordinate = PTMapCoordinate(latitude: 31.2, longitude: 121.4)
        let route = PTMapRoute(distance: 100, expectedTravelTime: 30, coordinates: [coordinate])
        let details = PTMapRouteDetails(route: route, eta: PTMapETA(distance: 100, expectedTravelTime: 30))
        XCTAssertEqual(details.route.coordinates.first, coordinate)
    }

    func testRealtimeSubscriptionAndRetryValueTypes() throws {
        var parser = PTSSEParser()
        _ = parser.consume("retry: 250")
        XCTAssertEqual(parser.reconnectDelay, .milliseconds(250))
        let subscription = PTRealtimeSubscription(topic: "orders")
        XCTAssertEqual(subscription.id.rawValue, "orders")
    }

    func testAppIntegrityChallengeIsSingleUse() async throws {
        let keyStore = PTTestIntegrityKeyStore()
        try await keyStore.save(keyID: "demo-key")
        let service = PTAppIntegrityService(keyStore: keyStore)
        let challenge = PTAppIntegrityChallenge(nonce: Data("nonce".utf8),
                                                expiresAt: .distantFuture)
        let payload = try await service.assert(challenge: challenge, artifact: Data("assertion".utf8))
        XCTAssertEqual(payload.keyID, "demo-key")
        do {
            _ = try await service.assert(challenge: challenge, artifact: Data())
            XCTFail("A challenge must not be accepted twice")
        } catch let error as PTAppIntegrityError {
            XCTAssertEqual(error, .challengeReplayed)
        }
    }

    func testConfigurationSnapshotKeepsWinningSource() async throws {
        let key = PTConfigKey(name: "feature.enabled", defaultValue: false)
        let data = try JSONEncoder().encode(true)
        let store = PTConfigurationStore(defaults: [key.name: data])
        let snapshot = try await store.refresh()
        XCTAssertEqual(snapshot.source(for: key.name), .defaults)
        XCTAssertTrue(try snapshot.value(for: key))
    }
}

private struct PTTestMigrationStep: PTDatabaseMigrationStep {
    let fromVersion: Int
    let toVersion: Int
    let isDestructive = false

    func migrate(using database: PTDatabase) async throws {
        try await database.execute("CREATE TABLE IF NOT EXISTS migration_demo (id INTEGER PRIMARY KEY)")
    }
}

private actor PTTestObservabilitySink: PTObservabilitySink {
    private(set) var records: [PTObservabilityRecord] = []
    func receive(_ record: PTObservabilityRecord) async { records.append(record) }
}

private actor PTTestAuthCredentialStore: PTAuthCredentialStore {
    private var token: PTAuthToken?
    func loadToken() async throws -> PTAuthToken? { token }
    func saveToken(_ token: PTAuthToken) async throws { self.token = token }
    func removeToken() async throws { token = nil }
}

private actor PTTestAuthRemoteProvider: PTAuthRemoteProvider {
    private(set) var refreshCount = 0
    func refresh(token: PTAuthToken) async throws -> PTAuthToken {
        refreshCount += 1
        try await Task.sleep(for: .milliseconds(5))
        return PTAuthToken(accessToken: "fresh", refreshToken: token.refreshToken, expiresAt: .distantFuture)
    }
}

private actor PTTestIntegrityKeyStore: PTAppIntegrityKeyStore {
    private var value: String?
    func keyID() async throws -> String? { value }
    func save(keyID: String) async throws { value = keyID }
    func removeKey() async throws { value = nil }
}
