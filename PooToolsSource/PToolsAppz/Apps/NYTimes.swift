// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct NYTimes: PTExternalApplication {
        
        public typealias ActionType = Applications.NYTimes.Action
        
        public let scheme = "nytimes:"
        public let fallbackURL = "http://www.nytimes.com/services/mobile/index.html"
        public let appStoreId = "284862083"
        
        public init() {}
    }
}


public extension Applications.NYTimes {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.NYTimes.Action: PTExternalApplicationAction {
    
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
