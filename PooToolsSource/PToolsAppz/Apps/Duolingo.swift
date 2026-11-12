// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Duolingo: PTExternalApplication {
        
        public typealias ActionType = Applications.Duolingo.Action
        
        public let scheme = "duolingo:"
        public let fallbackURL = "https://www.duolingo.com"
        public let appStoreId = "570060128"
        
        public init() {}
    }
}


public extension Applications.Duolingo {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Duolingo.Action: PTExternalApplicationAction {
    
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
