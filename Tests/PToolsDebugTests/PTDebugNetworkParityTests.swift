// English: Prove that observing a request does not change its business response.
// Español: Demuestra que observar una solicitud no cambia su respuesta de negocio.
// 中文：验证观测请求不会改变业务响应。

import XCTest
@testable import PooToolsDEBUG

final class PTDebugNetworkParityTests: XCTestCase {
    func testCaptureOffAndOnHaveIdenticalResponseContract() async throws {
        let off = try await requestObservation(path: "/post-json", capture: false)
        let on = try await requestObservation(path: "/post-json", capture: true)

        XCTAssertEqual(off.data, on.data)
        XCTAssertEqual(off.statusCode, on.statusCode)
        XCTAssertEqual(off.headers, on.headers)
        XCTAssertEqual(off.error, on.error)
    }

    private func requestObservation(path: String, capture: Bool) async throws -> Observation {
        let session = makePTDebugNetworkFixtureSession()
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: PTDebugNetworkHTTPFixture.url(path))
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"capture":\#(capture)}"#.utf8)
        let startedAt = Date()
        do {
            let (data, response) = try await session.data(for: request)
            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            if capture {
                let snapshot = PTNetworkRequestSnapshot(request: request, startedAt: startedAt)
                _ = await PTNetworkModuleCaptureAdapter.record(
                    request: snapshot,
                    response: PTNetworkCaptureResponseSnapshot(statusCode: httpResponse.statusCode,
                                                               headers: httpResponse.allHeaderFields.reduce(into: [:]) { result, pair in
                                                                   result[String(describing: pair.key)] = String(describing: pair.value)
                                                               },
                                                               body: .complete(data: data, totalBytes: Int64(data.count))),
                    timing: PTNetworkTiming(startedAt: startedAt, endedAt: .now),
                    completion: .completed
                )
            }
            return Observation(data: data,
                               statusCode: httpResponse.statusCode,
                               headers: httpResponse.allHeaderFields.reduce(into: [:]) { result, pair in
                                   result[String(describing: pair.key)] = String(describing: pair.value)
                               },
                               error: nil)
        } catch {
            return Observation(data: Data(), statusCode: nil, headers: [:], error: String(describing: error))
        }
    }

    private struct Observation: Equatable {
        let data: Data
        let statusCode: Int?
        let headers: [String: String]
        let error: String?
    }
}
