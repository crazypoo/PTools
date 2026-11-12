// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Sonos: PTExternalApplication {
        
        public typealias ActionType = Applications.Sonos.Action
        
        public let scheme = "sonos:"
        public let fallbackURL = "http://www.sonos.com/"
        public let appStoreId = "293523031"
        
        public init() {}
    }
}


public extension Applications.Sonos {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Sonos.Action: PTExternalApplicationAction {
    
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
