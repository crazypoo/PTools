// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {

    struct CirclePay: PTExternalApplication {

        public typealias ActionType = Applications.CirclePay.Action

        public let scheme = "circle:"
        public let fallbackURL = "https://www.circle.com/"
        public let appStoreId = "920164002"

        public init() {}
    }
}


public extension Applications.CirclePay {

    enum Action: Sendable {
        case open
        case request
        case send
    }
}

extension Applications.CirclePay.Action: PTExternalApplicationAction {

    public var paths: PTApplicationActionPaths {

        switch self {
        case .open:
            return PTApplicationActionPaths()

        case .request:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["request"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["request"],
                    queryParameters: [:]
                )
            )

        case .send:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["send"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["send"],
                    queryParameters: [:]
                )
            )
        }
    }
}
