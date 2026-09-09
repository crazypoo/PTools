import Foundation
import XCTest
@testable import PooToolsNetWork

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
}
