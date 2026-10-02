// English: Provide an in-process URLProtocol so DebugNetwork tests never depend on a live host.
// Español: Proporciona un URLProtocol en proceso para que las pruebas nunca dependan de un host real.
// 中文：提供进程内 URLProtocol，让测试不依赖真实网络主机。

import Foundation

final class PTDebugNetworkURLProtocolStub: URLProtocol, @unchecked Sendable {
    private var stopped = false

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "ptools.fixture"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let fixture = PTDebugNetworkHTTPFixture.response(for: request)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, !self.stopped else { return }
            guard let url = self.request.url else {
                self.client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            if let error = fixture.error {
                self.client?.urlProtocol(self, didFailWithError: URLError(error))
                return
            }
            guard let response = HTTPURLResponse(url: url,
                                                 statusCode: fixture.statusCode,
                                                 httpVersion: "HTTP/1.1",
                                                 headerFields: fixture.headers) else {
                self.client?.urlProtocol(self, didFailWithError: URLError(.cannotParseResponse))
                return
            }
            if let redirectURL = fixture.redirectURL {
                let redirectRequest = URLRequest(url: redirectURL)
                self.client?.urlProtocol(self,
                                         wasRedirectedTo: redirectRequest,
                                         redirectResponse: response)
                return
            }
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            let chunks = fixture.chunks.isEmpty ? [fixture.body] : fixture.chunks
            for chunk in chunks where !chunk.isEmpty {
                guard !self.stopped else { return }
                self.client?.urlProtocol(self, didLoad: chunk)
            }
            guard !self.stopped else { return }
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        stopped = true
    }
}

func makePTDebugNetworkFixtureSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [PTDebugNetworkURLProtocolStub.self]
    return URLSession(configuration: configuration)
}
