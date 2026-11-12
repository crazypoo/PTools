// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct AirLaunch: PTExternalApplication {
        
        public typealias ActionType = Applications.AirLaunch.Action
        
        public let scheme = "airlaunch:"
        public let fallbackURL = "http://www.iosappdownload.org/download.php?boaID=846864"
        public let appStoreId = "993479740"
        
        public init() {}
    }
}


public extension Applications.AirLaunch {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.AirLaunch.Action: PTExternalApplicationAction {
    
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
