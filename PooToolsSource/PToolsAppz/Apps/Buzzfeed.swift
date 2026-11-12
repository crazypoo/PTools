// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Buzzfeed: PTExternalApplication {
        
        public typealias ActionType = Applications.Buzzfeed.Action
        
        public let scheme = "buzzfeed:"
        public let fallbackURL = "http://www.buzzfeed.com"
        public let appStoreId = "352969997"
        
        public init() {}
    }
}


public extension Applications.Buzzfeed {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Buzzfeed.Action: PTExternalApplicationAction {
    
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
