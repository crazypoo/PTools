// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Behance: PTExternalApplication {
        
        public typealias ActionType = Applications.Behance.Action
        
        public let scheme = "behance:"
        public let fallbackURL = "https://www.behance.net/"
        public let appStoreId = "489667151"
        
        public init() {}
    }
}


public extension Applications.Behance {
    
    enum Action: Sendable {
        case open
        case userProfile(String)
    }
}

extension Applications.Behance.Action: PTExternalApplicationAction {
    
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
            
        case .userProfile(let profile):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["profile", profile],
                    queryParameters: [:]
                ),
                web: PTApplicationPath(
                    pathComponents: [profile],
                    queryParameters: [:]
                )
            )
        }
    }
}
