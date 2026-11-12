// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct EyeEm: PTExternalApplication {
        
        public typealias ActionType = Applications.EyeEm.Action
        
        public let scheme = "eyeem:"
        public let fallbackURL = "https://www.eyeem.com/community"
        public let appStoreId = "445638931"
        
        public init() {}
    }
}


public extension Applications.EyeEm {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.EyeEm.Action: PTExternalApplicationAction {
    
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
