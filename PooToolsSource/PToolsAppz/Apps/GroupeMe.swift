// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GroupeMe: PTExternalApplication {
        
        public typealias ActionType = Applications.GroupeMe.Action
        
        public let scheme = "groupme:"
        public let fallbackURL = "https://groupme.com"
        public let appStoreId = "392796698"
        
        public init() {}
    }
}


public extension Applications.GroupeMe {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GroupeMe.Action: PTExternalApplicationAction {
    
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
