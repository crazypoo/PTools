// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Snapchat: PTExternalApplication {
        
        public typealias ActionType = Applications.Snapchat.Action
        
        public let scheme = "snapchat:"
        public let fallbackURL = "https://www.snapchat.com"
        public let appStoreId = "447188370"
        
        public init() {}
    }
}


public extension Applications.Snapchat {
    
    enum Action: Sendable {
        case open
        case add(username: String)
    }
}

extension Applications.Snapchat.Action: PTExternalApplicationAction {
    
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
        case .add(let Username):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["add", Username],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
