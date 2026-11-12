// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Strava: PTExternalApplication {
        
        public typealias ActionType = Applications.Strava.Action
        
        public let scheme = "strava:"
        public let fallbackURL = "http://www.strava.com/mobile"
        public let appStoreId = "426826309"
        
        public init() {}
    }
}


public extension Applications.Strava {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Strava.Action: PTExternalApplicationAction {
    
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
