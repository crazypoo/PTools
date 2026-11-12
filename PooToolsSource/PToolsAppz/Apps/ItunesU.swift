// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct ItunesU: PTExternalApplication {
        
        public typealias ActionType = Applications.ItunesU.Action
        
        public let scheme = "itms-itunesu:"
        public let fallbackURL = "https://itunes.apple.com/kw/app/itunes-u/id490217893?mt=8"
        public let appStoreId = "490217893"
        
        public init() {}
    }
}


public extension Applications.ItunesU {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.ItunesU.Action: PTExternalApplicationAction {
    
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
