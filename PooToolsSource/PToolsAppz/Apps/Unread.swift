// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Unread: PTExternalApplication {
        
        public typealias ActionType = Applications.Unread.Action
        
        public let scheme = "unread:"
        public let fallbackURL = "http://supertop.co/unread/"
        public let appStoreId = "911364254"
        
        public init() {}
    }
}


public extension Applications.Unread {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Unread.Action: PTExternalApplicationAction {
    
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
