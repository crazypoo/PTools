// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct OnePassword: PTExternalApplication {
        
        public typealias ActionType = Applications.OnePassword.Action
        
        public let scheme = "onepassword:"
        public let fallbackURL = "https://agilebits.com/onepassword"
        public let appStoreId = "568903335"
        
        public init() {}
    }
}


public extension Applications.OnePassword {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.OnePassword.Action: PTExternalApplicationAction {
    
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
