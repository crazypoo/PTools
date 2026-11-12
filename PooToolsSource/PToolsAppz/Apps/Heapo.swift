// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Heapo: PTExternalApplication {
        
        public typealias ActionType = Applications.Heapo.Action
        
        public let scheme = "heap:"
        public let fallbackURL = "https://itunes.apple.com/us/app/heapo-clipboard-management-widget-copy-paste-clips/id921961118?mt=8"
        public let appStoreId = "921961118"
        
        public init() {}
    }
}


public extension Applications.Heapo {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Heapo.Action: PTExternalApplicationAction {
    
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
