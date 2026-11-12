// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct INRIXTraffic: PTExternalApplication {
        
        public typealias ActionType = Applications.INRIXTraffic.Action
        
        public let scheme = "inrixtraffic:"
        public let fallbackURL = "http://inrix.com/inrix-traffic-app/"
        public let appStoreId = "324384027"
        
        public init() {}
    }
}


public extension Applications.INRIXTraffic {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.INRIXTraffic.Action: PTExternalApplicationAction {
    
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
