// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Waze: PTExternalApplication {
        
        public typealias ActionType = Applications.Waze.Action
        
        public let scheme = "waze:"
        public let fallbackURL = "https://www.waze.com"
        public let appStoreId = "323229106"
        
        public init() {}
    }
}


public extension Applications.Waze {
    
    enum Action: Sendable {
        case open
        case navigateToDirection(lat:String, lng:String)
    }
}

extension Applications.Waze.Action: PTExternalApplicationAction {
    
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
        case .navigateToDirection(let lat, let lng):
            
            let ll = "\(lat),\(lng)"
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: [""],
                    queryParameters: [
                        "ll": ll,
                        "navigate": "yes",
                    ]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
