// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Viber: PTExternalApplication {
        
        public typealias ActionType = Applications.Viber.Action
        
        public let scheme = "viber:"
        public let fallbackURL = "http://www.viber.com/"
        public let appStoreId = "382617920"
        
        public init() {}
    }
}


public extension Applications.Viber {
    
    enum Action: Sendable {
        
        case callsTab
        case chatsTab
    }
}

extension Applications.Viber.Action: PTExternalApplicationAction {
    
    public var paths: PTApplicationActionPaths {
        
        switch self {
            
        case .callsTab:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["calls"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
            
        case .chatsTab:
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["chats"],
                    queryParameters: [:]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
