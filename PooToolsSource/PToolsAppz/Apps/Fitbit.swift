// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Fitbit: PTExternalApplication {
        
        public typealias ActionType = Applications.Fitbit.Action
        
        public let scheme = "fitbit:"
        public let fallbackURL = "https://www.fitbit.com/app"
        public let appStoreId = "462638897"
        
        public init() {}
    }
}


public extension Applications.Fitbit {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Fitbit.Action: PTExternalApplicationAction {
    
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
