import Foundation
import XCTest
import PToolsNetworkModelCore
@testable import PooToolsNetWork

final class PTNetworkHTMLResponseTests: XCTestCase {
    private func snapshot(_ body: String, contentType: String, status: Int = 200) -> PTNetworkResponseSnapshot {
        PTNetworkResponseSnapshot(
            url: "https://example.invalid/api",
            data: Data(body.utf8),
            metadata: PTResponseMetadata(statusCode: status, headers: ["Content-Type": contentType])
        )
    }

    func testHTMLMaintenancePagePreservesBodyEvenIfContentTypeSaysJSON() throws {
        let html = "<!DOCTYPE html>\n<html><head><title>Home</title></head><body>We're Working Hard...</body></html>"
        let response = snapshot(html, contentType: "application/json; charset=UTF-8")
        do {
            try Network.rejectHTMLResponse(response)
            XCTFail("Expected a typed HTML response error")
        } catch PTNetworkError.htmlResponse(let original) {
            XCTAssertEqual(original, html)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeclaredHTMLOnHTTP502PreservesRawBody() throws {
        let html = "<div>Maintenance</div>"
        let response = snapshot(html, contentType: "text/html; charset=UTF-8", status: 502)
        do {
            try Network.parseCodableResponse(response, modelType: HTMLFixtureDTO.self)
            XCTFail("Expected HTML response, not a decoding error")
        } catch PTNetworkError.htmlResponse(let original) {
            XCTAssertEqual(original, html)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNormalJSONAndJSONStringContainingHTMLAreNotMisclassified() throws {
        let json = #"{ "code": "100001", "msg": "<html>literal text</html>" }"#
        let response = snapshot(json, contentType: "application/json")
        XCTAssertNoThrow(try Network.rejectHTMLResponse(response))
        let result: PTBaseStructModel<HTMLFixtureDTO> = try Network.parseCodableResponse(
            response, modelType: HTMLFixtureDTO.self
        )
        XCTAssertEqual(result.customerModel?.msg, "<html>literal text</html>")
    }

    func testEmptyBodyIsNotMisclassifiedAsHTML() throws {
        XCTAssertNoThrow(try Network.rejectHTMLResponse(snapshot("", contentType: "text/html")))
    }
}

private struct HTMLFixtureDTO: Codable, Sendable {
    let code: String
    let msg: String
}
