// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct MobileMouse: PTExternalApplication {
        
        public typealias ActionType = Applications.MobileMouse.Action
        
        public let scheme = "mobilemouse:"
        public let fallbackURL = "http://www.mobilemouse.com"
        public let appStoreId = "356395556"
        
        public init() {}
    }
}


public extension Applications.MobileMouse {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.MobileMouse.Action: PTExternalApplicationAction {
    
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
