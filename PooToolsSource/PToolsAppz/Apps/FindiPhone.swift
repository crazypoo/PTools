// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct FindiPhone: PTExternalApplication {
        
        public typealias ActionType = Applications.FindiPhone.Action
        
        public let scheme = "fmip1:"
        public let fallbackURL = "https://itunes.apple.com/us/app/find-my-iphone/id376101648?mt=8"
        public let appStoreId = "376101648"
        
        public init() {}
    }
}


public extension Applications.FindiPhone {
    
    enum Action: Sendable {
        case open
    }
}


extension Applications.FindiPhone.Action: PTExternalApplicationAction {
    
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
