import XCTest
@testable import PToolsDatabase
@testable import PToolsRealtimeCore

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

    func testSSEParserCombinesDataLines() {
        var parser = PTSSEParser()
        XCTAssertNil(parser.consume("event: update"))
        XCTAssertNil(parser.consume("id: 7"))
        XCTAssertNil(parser.consume("data: first"))
        XCTAssertNil(parser.consume("data: second"))

        let event = parser.finish()
        XCTAssertEqual(event, PTRealtimeEvent(event: "update", data: "first\nsecond", id: "7"))
    }
}
