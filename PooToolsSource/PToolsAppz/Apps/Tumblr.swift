// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Tumblr: PTExternalApplication {
        
        public typealias ActionType = Applications.Tumblr.Action
        
        public let scheme = "tumblr:"
        public let fallbackURL = "https://www.tumblr.com"
        public let appStoreId = "305343404"
        
        public init() {}
    }
}


public extension Applications.Tumblr {
    
    enum Action: Sendable {
        case open
        case dashboard
        case explore
        case activity
        case blog
        case tag(tag: String)
    }
}

extension Applications.Tumblr.Action: PTExternalApplicationAction {
    
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
            
        case .dashboard:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["x-callback-url", "dashboard"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
            
        case .explore:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["x-callback-url", "explore"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
            
        case .activity:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["x-callback-url", "activity"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
            
        case .blog:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["x-callback-url", "blog"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
          
        case .tag(let tag):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["x-callback-url", "tag"],
                    queryParameters:
                    [
                        "tag":tag
                    ]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
