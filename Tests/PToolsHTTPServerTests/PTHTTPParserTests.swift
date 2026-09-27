import Foundation
import XCTest
@testable import PToolsHTTPServer

final class PTHTTPParserTests: XCTestCase {
    func testFixedLengthBodyCanArriveInMultipleReads() throws {
        var parser = PTHTTPParser()
        XCTAssertTrue(try parser.append(Data("POST /upload?name=a HTTP/1.1\r\nHost: localhost\r\nContent-Length: 5\r\n\r\nhe".utf8)).isEmpty)

        let requests = try parser.append(Data("llo".utf8))
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].method, .post)
        XCTAssertEqual(requests[0].path, "/upload")
        XCTAssertEqual(requests[0].query["name"], "a")
        guard case .data(let body) = requests[0].body else {
            return XCTFail("Expected an in-memory request body")
        }
        XCTAssertEqual(body, Data("hello".utf8))
    }

    func testChunkedBodyAndTrailers() throws {
        var parser = PTHTTPParser()
        let request = try XCTUnwrap(parser.append(Data("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nWiki\r\n5\r\npedia\r\n0\r\nX-Test: yes\r\n\r\n".utf8)).first)

        guard case .data(let body) = request.body else {
            return XCTFail("Expected an in-memory request body")
        }
        XCTAssertEqual(body, Data("Wikipedia".utf8))
        XCTAssertEqual(request.trailers.firstValue(for: "X-Test"), "yes")
    }

    func testConflictingFramingIsRejected() {
        var parser = PTHTTPParser()
        XCTAssertThrowsError(try parser.append(Data("POST / HTTP/1.1\r\nContent-Length: 1\r\nTransfer-Encoding: chunked\r\n\r\n".utf8))) { error in
            XCTAssertEqual((error as? PTHTTPParserError)?.status, .badRequest)
        }
    }

    func testDuplicateContentLengthIsRejected() {
        var parser = PTHTTPParser()
        XCTAssertThrowsError(try parser.append(Data("POST / HTTP/1.1\r\nContent-Length: 1\r\nContent-Length: 1\r\n\r\na".utf8)))
    }
}
