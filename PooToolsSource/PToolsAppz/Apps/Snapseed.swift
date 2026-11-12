// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Snapseed: PTExternalApplication {
        
        public typealias ActionType = Applications.Snapseed.Action
        
        public let scheme = "googlesnapseed:"
        public let fallbackURL = "https://support.google.com/snapseed/#topic=6155507"
        public let appStoreId = "439438619"
        
        public init() {}
    }
}


public extension Applications.Snapseed {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Snapseed.Action: PTExternalApplicationAction {
    
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
