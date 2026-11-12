// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GooglePlus: PTExternalApplication {
        
        public typealias ActionType = Applications.GooglePlus.Action
        
        public let scheme = "gplus:"
        public let fallbackURL = "https://plus.google.com/"
        public let appStoreId = "447119634"
        
        public init() {}
    }
}


public extension Applications.GooglePlus {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GooglePlus.Action: PTExternalApplicationAction {
    
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
