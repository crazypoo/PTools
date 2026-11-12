// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GoogleEarth: PTExternalApplication {
        
        public typealias ActionType = Applications.GoogleEarth.Action
        
        public let scheme = "kml:"
        public let fallbackURL = "https://www.google.com/earth/"
        public let appStoreId = "293622097"
        
        public init() {}
    }
}


public extension Applications.GoogleEarth {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GoogleEarth.Action: PTExternalApplicationAction {
    
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
