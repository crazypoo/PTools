// English: Execute representative HTTP cases against the deterministic fixture.
// Español: Ejecuta casos HTTP representativos contra el fixture determinista.
// 中文：使用确定性 fixture 执行代表性的 HTTP 场景。

import XCTest
@testable import PooToolsDEBUG

final class PTDebugNetworkCaptureMatrixTests: XCTestCase {
    func testGetPostFormAndStatusMatrix() async throws {
        let get = try await load(path: "/get")
        XCTAssertEqual(get.response.statusCode, 200)

        var jsonRequest = request(path: "/post-json", method: "POST")
        jsonRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        jsonRequest.httpBody = Data(#"{"name":"fixture"}"#.utf8)
        let jsonSnapshot = PTNetworkRequestSnapshot(request: jsonRequest)
        XCTAssertEqual(jsonSnapshot.method, "POST")
        XCTAssertEqual(jsonSnapshot.body.totalBytes, Int64(jsonRequest.httpBody?.count ?? 0))
        XCTAssertEqual(try await load(request: jsonRequest).response.statusCode, 200)

        var formRequest = request(path: "/form", method: "POST")
        formRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        formRequest.httpBody = Data("name=fixture".utf8)
        XCTAssertEqual(try await load(request: formRequest).response.statusCode, 200)

        XCTAssertEqual(try await load(path: "/client-error").response.statusCode, 404)
        XCTAssertEqual(try await load(path: "/server-error").response.statusCode, 503)
    }

    func testRedirectChunkedGzipAndLargeResponse() async throws {
        let redirect = try await load(path: "/redirect")
        XCTAssertEqual(redirect.response.statusCode, 200)
        XCTAssertEqual(String(decoding: redirect.data, as: UTF8.self), #"{"path":"/get"}"#)

        let chunked = try await load(path: "/chunked")
        XCTAssertEqual(chunked.data, Data("onetwothree".utf8))

        var gzipRequest = request(path: "/gzip")
        let gzip = try await load(request: gzipRequest)
        XCTAssertEqual(gzip.response.value(forHTTPHeaderField: "Content-Encoding"), "gzip")

        let large = try await load(path: "/large-response")
        XCTAssertEqual(large.data.count, 4_096)
    }

    func testCancellationAndTimeoutFinishWithErrors() async {
        let session = makePTDebugNetworkFixtureSession()
        defer { session.invalidateAndCancel() }

        let cancelTask = Task { try await session.data(for: request(path: "/cancel")) }
        cancelTask.cancel()
        do {
            _ = try await cancelTask.value
            XCTFail("cancelled request unexpectedly completed")
        } catch {
            XCTAssertTrue((error as? URLError)?.code == .cancelled || error is CancellationError)
        }

        do {
            _ = try await session.data(for: request(path: "/timeout"))
            XCTFail("timeout request unexpectedly completed")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
        }
    }

    func testHTTPBodyStreamIsRepresentedWithoutConsumingTheStream() {
        var streamRequest = request(path: "/large-request", method: "POST")
        streamRequest.httpBodyStream = InputStream(data: Data(repeating: 1, count: 64))
        let snapshot = PTNetworkRequestSnapshot(request: streamRequest)
        XCTAssertEqual(snapshot.body.totalBytes, -1)
        XCTAssertEqual(snapshot.body.previewData, Data())
    }

    private func request(path: String, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: PTDebugNetworkHTTPFixture.url(path))
        request.httpMethod = method
        request.timeoutInterval = 1
        return request
    }

    private func load(path: String) async throws -> (data: Data, response: HTTPURLResponse) {
        try await load(request: request(path: path))
    }

    private func load(request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        let session = makePTDebugNetworkFixtureSession()
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        return (data, try XCTUnwrap(response as? HTTPURLResponse))
    }
}
