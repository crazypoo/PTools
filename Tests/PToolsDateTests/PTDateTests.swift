//
//  PTDateTests.swift
//  PooTools
//
//  English: Small Foundation-only regression checks for the 5.26 date contract.
//  Español: Comprobaciones pequeñas basadas solo en Foundation para el contrato de fechas 5.26.
//  中文：5.26 日期契约的 Foundation-only 小型回归检查。
//

import XCTest
@testable import PToolsDate

final class PTDateTests: XCTestCase {
    func testTimestampUnitsPreserveTheSameInstant() {
        let expected = Date(timeIntervalSince1970: 1_725_000_123.456)

        XCTAssertEqual(
            Date.fromTimestamp(expected.timestamp(unit: .seconds), unit: .seconds),
            expected
        )
        XCTAssertEqual(
            Date.fromTimestamp(expected.timestamp(unit: .milliseconds), unit: .milliseconds),
            expected,
            accuracy: 0.001
        )
    }

    func testStrictParsingRejectsInvalidCalendarDate() {
        XCTAssertThrowsError(try PTDateParser.parse(
            "2024-02-30",
            strategy: .pattern("yyyy-MM-dd"),
            context: .posixUTC
        ))
    }

    func testCalendarAdditionUsesTheSelectedTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let context = PTDateContext(calendar: calendar)
        let beforeDST = try XCTUnwrap(
            PTDateParser.parse(
                "2024-03-09 12:00:00",
                strategy: .pattern("yyyy-MM-dd HH:mm:ss"),
                context: context
            )
        ).zoned(in: context)

        let afterDST = beforeDST.adding(.days(1))
        XCTAssertEqual(afterDST.hour, 12)
        XCTAssertEqual(afterDST.day, 10)
        XCTAssertEqual(afterDST.date.timeIntervalSince(beforeDST.date), 23 * 60 * 60, accuracy: 0.001)
    }

    func testFormattingRetainsTheContextTimeZone() throws {
        let context = PTDateContext(
            calendar: Calendar(identifier: .gregorian),
            timeZone: try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai")),
            locale: Locale(identifier: "en_US_POSIX")
        )
        let value = Date(timeIntervalSince1970: 0).zoned(in: context)

        XCTAssertEqual(value.formatted(pattern: "yyyy-MM-dd HH:mm:ss"), "1970-01-01 08:00:00")
    }
}
