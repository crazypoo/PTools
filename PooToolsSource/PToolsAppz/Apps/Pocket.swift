// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Pocket: PTExternalApplication {
        
        public typealias ActionType = Applications.Pocket.Action
        
        public let scheme = "pocket:"
        public let fallbackURL = "https://getpocket.com/ios/?ep=1"
        public let appStoreId = "309601447"
        
        public init() {}
    }
}


public extension Applications.Pocket {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Pocket.Action: PTExternalApplicationAction {
    
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
