// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Pinterest: PTExternalApplication {
        
        public typealias ActionType = Applications.Pinterest.Action
        
        public let scheme = "pinterest:"
        public let fallbackURL = "https://www.pinterest.com/"
        public let appStoreId = "429047995"
        
        public init() {}
    }
}


public extension Applications.Pinterest {
    
    enum Action: Sendable {
        case open
        case user(name: String)
        case search(query: String)
    }
}


extension Applications.Pinterest.Action: PTExternalApplicationAction {
    
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
            
        case .user(let name):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["user", name],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: [name],
                    queryParameters: [:]
                )
            )
            
        case .search(let query):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["search", "pins"],
                    queryParameters: ["q":query]
                ),
                web: PTApplicationPath(
                    pathComponents: ["search", "pins"],
                    queryParameters: ["q":query]
                )
            )
        }
    }
}
