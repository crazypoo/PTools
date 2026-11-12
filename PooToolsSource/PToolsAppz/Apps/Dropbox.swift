// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Dropbox: PTExternalApplication {
        
        public typealias ActionType = Applications.Dropbox.Action
        
        public let scheme = "dbapi-2:"
        public let fallbackURL = "https://dropbox.com/"
        public let appStoreId = "327630330"
        
        public init() {}
    }
}


public extension Applications.Dropbox {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Dropbox.Action: PTExternalApplicationAction {
    
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
