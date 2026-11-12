// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Ustream: PTExternalApplication {
        
        public typealias ActionType = Applications.Ustream.Action
        
        public let scheme = "ustream:"
        public let fallbackURL = "https://www.ustream.tv/platform/watch-everywhere"
        public let appStoreId = "301520250"
        
        public init() {}
    }
}


public extension Applications.Ustream {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Ustream.Action: PTExternalApplicationAction {
    
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
