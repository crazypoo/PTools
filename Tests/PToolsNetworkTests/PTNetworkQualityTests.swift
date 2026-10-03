import Foundation
import XCTest
import Alamofire
import PToolsCore
import PToolsNetworkModelCore
@testable import PooToolsNetWork

// English: This test-only URLProtocol wrapper crosses GCD's callback boundary and owns no production state.
// Español: Este wrapper URLProtocol solo de pruebas cruza el límite de callbacks de GCD y no posee estado de producción.
// 中文：这个仅用于测试的 URLProtocol 包装器会跨越 GCD 回调边界，但不持有生产状态。
final class PTNetworkFixtureURLProtocol: URLProtocol, @unchecked Sendable {
    // English: Keep cancellation state local to each URLProtocol fixture instance.
    // Español: Mantiene el estado de cancelación local a cada instancia del fixture URLProtocol.
    // 中文：让取消状态只属于当前 URLProtocol 夹具实例。
    private var didStopLoading = false

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.scheme == "ptfixture"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: PTNetworkFixtureError.invalidURL)
            return
        }
        let response = HTTPURLResponse(url: url,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])
        let send: @Sendable () -> Void = { [weak self] in
            guard let self, !self.didStopLoading else { return }
            let data = Data(#"{"code":200,"msg":"ok","value":7}"#.utf8)
            if let response = response {
                self.client?.urlProtocol(self,
                                         didReceive: response,
                                         cacheStoragePolicy: .notAllowed)
            }
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
        if url.path == "/cancel" {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.25, execute: send)
        } else {
            send()
        }
    }

    override func stopLoading() {
        didStopLoading = true
    }
}

enum PTNetworkFixtureError: Error {
    case invalidURL
}

actor PTNetworkInvocationCounter {
    private var invocationCount = 0

    func increment() {
        invocationCount += 1
    }

    func value() -> Int {
        invocationCount
    }
}

final class PTNetworkQualityTests: XCTestCase {
    private func makeRequest(body: String? = nil) -> URLRequest? {
        guard let url = URL(string: "https://example.com/items") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let body {
            request.httpBody = Data(body.utf8)
        }
        return request
    }

    func testRequestKeyUsesStableJSONBodyIdentity() {
        guard let first = makeRequest(body: "{\"b\":2,\"a\":1}"),
              let second = makeRequest(body: "{\"a\":1,\"b\":2}") else {
            XCTFail("无法创建测试请求")
            return
        }

        let firstKey = RequestKey(request: first, responseType: String.self)
        let secondKey = RequestKey(request: second, responseType: String.self)

        XCTAssertEqual(firstKey, secondKey)
        XCTAssertEqual(firstKey.hashValue, secondKey.hashValue)
    }

    func testOneHundredConcurrentIdenticalRequestsShareOneOperation() async throws {
        guard let request = makeRequest(body: "{\"value\":1}") else {
            XCTFail("无法创建测试请求")
            return
        }

        let counter = PTNetworkInvocationCounter()
        let work: @Sendable () async throws -> PTBaseStructModel<String> = {
            await counter.increment()
            try await Task.sleep(nanoseconds: 20_000_000)
            var result = PTBaseStructModel<String>()
            result.customerModel = "ok"
            return result
        }

        let completedCount = try await withThrowingTaskGroup(of: PTBaseStructModel<String>.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    try await RequestDeduplicator.shared.execute(request: request,
                                                                  policy: .identical,
                                                                  task: work)
                }
            }

            var count = 0
            while let _ = try await group.next() {
                count += 1
            }
            return count
        }

        let invocationCount = await counter.value()
        XCTAssertEqual(completedCount, 100)
        XCTAssertEqual(invocationCount, 1)
    }

    func testMeasureRequestKeyConstructionForOneHundredRequests() {
        let requests = (0..<100).compactMap { index in
            makeRequest(body: "{\"index\":\(index)}")
        }
        XCTAssertEqual(requests.count, 100)

        measure {
            _ = requests.map { RequestKey(request: $0, responseType: String.self) }
        }
    }

    func testLegacyParameterEncodingAndNilModelTypeUseTheSameWireRequest() async throws {
        let url = "https://example.com/ptmodel-legacy-\(UUID().uuidString)"
        let parameters: Parameters = ["id": 17, "query": "PTools"]
        var seeded = try URLRequest(url: url, method: .get,
                                    headers: Network.prepareRequestHeaders(header: nil,
                                                                          jsonRequest: false,
                                                                          cachePolicy: .cacheElseNetwork))
        seeded = try Network.encodeParameters(parameters,
                                              into: seeded,
                                              encoder: URLEncoding.default,
                                              jsonRequest: false)
        let payload = Data(#"{"code":200,"msg":"cached","value":7}"#.utf8)
        await NetworkCache.shared.save(data: payload,
                                       request: seeded,
                                       expire: 60,
                                       headers: ["Content-Type": "application/json"],
                                       statusCode: 200)

        let result: PTBaseStructModel<Any> = try await Network.requestApi(
            needGobal: false,
            urlStr: url,
            method: .get,
            parameters: parameters,
            cachePolicy: .cacheElseNetwork,
            modelType: nil,
            encoder: URLEncoding.default)
        XCTAssertEqual(result.resultData, payload)
        XCTAssertNil(result.customerModel)
        XCTAssertTrue(result.originalString.contains("cached"))
    }

    func testLegacyBodyUploadAndTypedResponseParsingShareTheSameSnapshotContract() async throws {
        let payload = Data(#"{"code":200,"msg":"ok","value":7}"#.utf8)
        let snapshot = PTNetworkResponseSnapshot(url: "ptfixture://response",
                                                  data: payload,
                                                  metadata: PTResponseMetadata(statusCode: 200,
                                                                                headers: ["Content-Type": "application/json"]))
        let typed = try Network.parseCodableResponse(snapshot, modelType: PTNetworkFixtureModel.self)
        XCTAssertEqual(typed.customerModel?.value, 7)

        let legacy = try Network.parseResponse(snapshot, modelType: nil)
        XCTAssertEqual(legacy.resultData, payload)
        XCTAssertNil(legacy.customerModel)

        let network = Network(configuration: PTNetworkConfig(),
                              plugins: [],
                              protocolClasses: [PTNetworkFixtureURLProtocol.self])
        var request = URLRequest(url: URL(string: "ptfixture://upload")!)
        request.httpMethod = "POST"
        let body = Data("body".utf8)
        let transport = try await network.executeLegacyRequest(url: request.url!.absoluteString,
                                                                request: request,
                                                                uploadBody: body)
        XCTAssertEqual(transport.data, payload)
    }

    // English: Exercise the typed executor and legacy transport against the same host fixture.
    // Español: Ejecuta el executor tipado y el transporte heredado contra el mismo fixture de host.
    // 中文：让类型化执行器和旧版传输同时经过同一个宿主夹具，冻结两条入口的响应契约。
    func testTypedAndLegacyHostEndpointsShareTransportContract() async throws {
        let network = Network(configuration: PTNetworkConfig(),
                              plugins: [],
                              protocolClasses: [PTNetworkFixtureURLProtocol.self])
        let request = PTNetworkRequest(url: URL(string: "ptfixture://typed")!,
                                       method: "POST",
                                       body: Data("body".utf8),
                                       cachePolicy: .none,
                                       deduplication: .none)
        let executor = PTNetworkExecutor(network: network)
        let (typedResponse, typedModel) = try await executor.execute(
            request,
            decoder: .ptModel(PTNetworkFixtureModel.self))

        var legacyRequest = URLRequest(url: request.url)
        legacyRequest.httpMethod = request.method
        legacyRequest.httpBody = request.body
        legacyRequest.cachePolicyType = .none
        legacyRequest.dedupPolicy = .none
        let legacyResponse = try await network.executeLegacyRequest(
            url: request.url.absoluteString,
            request: legacyRequest)

        XCTAssertEqual(typedModel.value, 7)
        XCTAssertEqual(typedResponse.statusCode, 200)
        XCTAssertEqual(typedResponse.data, legacyResponse.data)
    }

    func testLegacyTransportCancellationPropagatesToTheUnderlyingRequest() async throws {
        let network = Network(configuration: PTNetworkConfig(),
                              plugins: [],
                              protocolClasses: [PTNetworkFixtureURLProtocol.self])
        let request = URLRequest(url: URL(string: "ptfixture://cancel/cancel")!)
        let task = Task {
            try await network.executeLegacyRequest(url: request.url!.absoluteString,
                                                    request: request)
        }
        try await Task.sleep(for: .milliseconds(20))
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected transport cancellation")
        } catch is CancellationError {
            // English: Expected cancellation reaches the legacy transport boundary.
            // Español: La cancelación esperada llega al límite de transporte heredado.
            // 中文：预期的取消已传递到旧版传输边界。
        }
    }
}

private struct PTNetworkFixtureModel: Codable, Sendable {
    let value: Int
}
