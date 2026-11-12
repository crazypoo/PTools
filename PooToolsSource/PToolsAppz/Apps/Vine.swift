// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Vine: PTExternalApplication {
        
        public typealias ActionType = Applications.Vine.Action
        
        public let scheme = "vine:"
        public let fallbackURL = "https://vine.co"
        public let appStoreId = "592447445"
        
        public init() {}
    }
}


public extension Applications.Vine {
    
    enum Action: Sendable {
        case open
        case timelinesPopular
    }
}

extension Applications.Vine.Action: PTExternalApplicationAction {
    
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
            
        case .timelinesPopular:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["timelines", "popular"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: ["popular-now"],
                    queryParameters: [:]
                )
            )
        }
    }
}
