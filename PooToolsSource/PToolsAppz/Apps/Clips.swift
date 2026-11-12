// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Clips: PTExternalApplication {
        
        public typealias ActionType = Applications.Clips.Action
        
        public let scheme = "clips:"
        public let fallbackURL = "http://www.cleanshavenapps.com/clips/#download"
        public let appStoreId = "917638056"
        
        public init() {}
    }
}


public extension Applications.Clips {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Clips.Action: PTExternalApplicationAction {
    
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
