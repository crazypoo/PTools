// English: Keep deterministic HTTP cases local to the DebugNetwork test target.
// Español: Mantén los casos HTTP deterministas dentro del objetivo de pruebas de DebugNetwork.
// 中文：将确定性的 HTTP 场景限制在 DebugNetwork 测试 target 内。

import Foundation

struct PTDebugNetworkHTTPFixtureResponse: Sendable {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
    let redirectURL: URL?
    let error: URLError.Code?
    let chunks: [Data]

    init(statusCode: Int = 200,
         headers: [String: String] = ["Content-Type": "application/json"],
         body: Data = Data(#"{"ok":true}"#.utf8),
         redirectURL: URL? = nil,
         error: URLError.Code? = nil,
         chunks: [Data] = []) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.redirectURL = redirectURL
        self.error = error
        self.chunks = chunks
    }
}

enum PTDebugNetworkHTTPFixture {
    static func url(_ path: String) -> URL {
        URL(string: "https://ptools.fixture\(path)")!
    }

    static func response(for request: URLRequest) -> PTDebugNetworkHTTPFixtureResponse {
        let path = request.url?.path ?? "/missing"
        switch path {
        case "/get", "/post-json", "/form":
            return PTDebugNetworkHTTPFixtureResponse(body: Data(#"{"path":"\#(path)"}"#.utf8))
        case "/redirect":
            return PTDebugNetworkHTTPFixtureResponse(statusCode: 302,
                                                      headers: ["Location": url("/get").absoluteString],
                                                      body: Data(),
                                                      redirectURL: url("/get"))
        case "/cancel":
            return PTDebugNetworkHTTPFixtureResponse(body: Data(repeating: 0x63, count: 2_048))
        case "/timeout":
            return PTDebugNetworkHTTPFixtureResponse(error: .timedOut)
        case "/client-error":
            return PTDebugNetworkHTTPFixtureResponse(statusCode: 404, body: Data(#"{"error":"not-found"}"#.utf8))
        case "/server-error":
            return PTDebugNetworkHTTPFixtureResponse(statusCode: 503, body: Data(#"{"error":"unavailable"}"#.utf8))
        case "/large-request":
            return PTDebugNetworkHTTPFixtureResponse(body: Data(repeating: 0x72, count: 4_096))
        case "/large-response":
            return PTDebugNetworkHTTPFixtureResponse(body: Data(repeating: 0x6C, count: 4_096))
        case "/chunked":
            let chunks = [Data("one".utf8), Data("two".utf8), Data("three".utf8)]
            return PTDebugNetworkHTTPFixtureResponse(body: Data("onetwothree".utf8), chunks: chunks)
        case "/gzip":
            return PTDebugNetworkHTTPFixtureResponse(headers: ["Content-Encoding": "gzip"],
                                                      body: Data("compressed-fixture".utf8))
        default:
            return PTDebugNetworkHTTPFixtureResponse(statusCode: 404, body: Data())
        }
    }
}
