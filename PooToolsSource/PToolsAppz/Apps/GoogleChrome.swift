// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GoogleChrome: PTExternalApplication {
        
        public typealias ActionType = Applications.GoogleChrome.Action
        
        public let scheme = "googlechrome:"
        public let fallbackURL = "https://www.google.com/chrome/"
        public let appStoreId = "535886823"
        
        public init() {}
    }
}


public extension Applications.GoogleChrome {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GoogleChrome.Action: PTExternalApplicationAction {
    
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
