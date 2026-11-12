// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Flipboard: PTExternalApplication {
        
        public typealias ActionType = Applications.Flipboard.Action
        
        public let scheme = "Flipboard:"
        public let fallbackURL = "https://flipboard.com"
        public let appStoreId = "358801284"
        
        public init() {}
    }
}


public extension Applications.Flipboard {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Flipboard.Action: PTExternalApplicationAction {
    
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
