// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct AppleMaps: PTExternalApplication {
        
        public typealias ActionType = Applications.AppleMaps.Action
        
        public let scheme = "maps:"
        public let fallbackURL = ""
        public let appStoreId = ""
        
        public init() {}
    }
}



public extension Applications.AppleMaps {
    
    enum Action: Sendable {
        case open
        case displayDirections(saddr: String,
            daddr: String,
            directionsmode: String)
    }
}

extension Applications.AppleMaps.Action: PTExternalApplicationAction {
    
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
        case .displayDirections(let saddr, let daddr, let directionsmode):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["app"],
                    queryParameters: [
                        "saddr": saddr,
                        "daddr": daddr,
                        "dirflg": directionsmode,
                    ]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
