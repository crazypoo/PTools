// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Ted: PTExternalApplication {
        
        public typealias ActionType = Applications.Ted.Action
        
        public let scheme = "ted:"
        public let fallbackURL = "https://www.ted.com"
        public let appStoreId = "376183339"
        
        public init() {}
    }
}


public extension Applications.Ted {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Ted.Action: PTExternalApplicationAction {
    
    public var paths: PTApplicationActionPaths {
        
        switch self {
        case .open:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["app"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
