// English: Core-only regression tests prove the acknowledgement contract works without UIKit or the PTools umbrella.
// Español: Las pruebas del Core demuestran que el contrato funciona sin UIKit ni el umbrella de PTools.
// 中文：Core-only 回归测试证明该契约无需 UIKit 或 PTools 聚合模块即可工作。

import XCTest
@testable import PToolsAcknowledgementsCore

final class PTAcknowledgementsCoreTests: XCTestCase {
    private func makeManifest() throws -> PTLicenseManifest {
        let license = PTLicenseDocument(fileName: "LICENSE", text: "Permission is hereby granted.")
        let notice = PTLicenseDocument(fileName: "NOTICE", text: "Copyright Example")
        let entries = [
            PTAcknowledgement(
                id: "spm:example/foo@1.2.3",
                name: "Foo",
                version: "1.2.3",
                sourceManagers: [.swiftPM],
                repositoryURL: URL(string: "https://example.com/foo"),
                licenseExpression: "MIT",
                licenseTexts: [license],
                notices: [notice],
                verification: .verified
            ),
            PTAcknowledgement(
                id: "pod:Bar@2.0.0",
                name: "Bar",
                version: "2.0.0",
                sourceManagers: [.cocoaPods],
                repositoryURL: URL(string: "https://example.com/bar"),
                licenseExpression: "Apache-2.0",
                verification: .review
            )
        ]
        return try PTLicenseManifest(entries: entries)
    }

    func testQueryStatisticsAndLicenseLookup() throws {
        let manifest = try makeManifest()

        XCTAssertEqual(manifest.entries.map(\.name), ["Bar", "Foo"])
        XCTAssertEqual(manifest.search("foo").map(\.id), ["spm:example/foo@1.2.3"])
        XCTAssertEqual(
            manifest.filter(.init(sourceManagers: [.swiftPM], verification: [.verified])).map(\.name),
            ["Foo"]
        )
        XCTAssertEqual(try manifest.licenseText(for: "spm:example/foo@1.2.3"), "Permission is hereby granted.")
        XCTAssertEqual(manifest.statistics().totalDependencies, 2)
        XCTAssertEqual(manifest.statistics().missingLicenseCount, 1)
        XCTAssertEqual(manifest.statistics().reviewCount, 1)
    }

    func testExportsRoundTripAndKeepNoticeText() throws {
        let manifest = try makeManifest()
        let json = try manifest.export(.json)
        let decoded = try PTAcknowledgementsProvider.load(data: json)
        XCTAssertEqual(decoded, manifest)

        let text = String(decoding: try manifest.export(.text), as: UTF8.self)
        let noticeText = String(decoding: try manifest.export(.noticeText), as: UTF8.self)
        XCTAssertTrue(text.contains("Permission is hereby granted."))
        XCTAssertFalse(text.contains("Copyright Example"))
        XCTAssertTrue(noticeText.contains("NOTICE: NOTICE"))

        let csv = String(decoding: try manifest.export(.csv), as: UTF8.self)
        XCTAssertTrue(csv.hasPrefix("id,name,version"))
        XCTAssertTrue(csv.contains("\"Foo\""))
    }

    func testRepositoryCachesAndSupportsCustomDataSource() async throws {
        let manifest = try makeManifest()
        let repository = PTAcknowledgementsRepository(
            source: PTInMemoryAcknowledgementsDataSource(manifest: manifest)
        )

        async let first = repository.load()
        async let second = repository.load()
        let firstValue = try await first
        let secondValue = try await second
        XCTAssertEqual(firstValue, secondValue)
        let reloadedValue = try await repository.reload()
        XCTAssertEqual(reloadedValue, manifest)
        await repository.invalidateCache()
        let cachedValue = try await repository.load()
        XCTAssertEqual(cachedValue, manifest)
    }

    func testValidationAndMergeErrorsAreTyped() throws {
        let manifest = try makeManifest()
        XCTAssertThrowsError(try manifest.licenseText(for: "pod:Bar@2.0.0")) { error in
            XCTAssertEqual(error as? PTAcknowledgementsError, .licenseTextUnavailable(id: "pod:Bar@2.0.0"))
        }

        let conflict = try PTLicenseManifest(entries: [
            PTAcknowledgement(
                id: "spm:example/foo@1.2.3",
                name: "Foo",
                version: "1.2.3",
                sourceManagers: [.manual],
                repositoryURL: URL(string: "https://example.com/foo"),
                licenseTexts: [PTLicenseDocument(fileName: "LICENSE", text: "Different text")]
            )
        ])
        XCTAssertThrowsError(try manifest.merging(conflict)) { error in
            XCTAssertEqual(error as? PTAcknowledgementsError, .licenseConflict(id: "spm:example/foo@1.2.3"))
        }

        XCTAssertThrowsError(try PTAcknowledgementsProvider.load(data: Data("{}".utf8))) { error in
            XCTAssertEqual(error as? PTAcknowledgementsError, .invalidJSON)
        }
        XCTAssertThrowsError(try PTAcknowledgementsProvider.load(data: Data("{\"schemaVersion\":99,\"entries\":[]}".utf8))) { error in
            XCTAssertEqual(error as? PTAcknowledgementsError, .unsupportedSchema(actual: 99))
        }
    }
}
