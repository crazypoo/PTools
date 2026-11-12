// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Podcasts: PTExternalApplication {
        
        public typealias ActionType = Applications.Podcasts.Action
        
        public let scheme = "podcasts:"
        public let fallbackURL = "https://itunes.apple.com/us/app/podcasts/id525463029?mt=8"
        public let appStoreId = "525463029"
        
        public init() {}
    }
}


public extension Applications.Podcasts {
    
    enum Action: Sendable {
        case open
    }
}


extension Applications.Podcasts.Action: PTExternalApplicationAction {
    
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
