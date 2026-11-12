// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct DailyMotion: PTExternalApplication {
        
        public typealias ActionType = Applications.DailyMotion.Action
        
        public let scheme = "dailymotion:"
        public let fallbackURL = "http://www.dailymotion.com/"
        public let appStoreId = "336978041"
        
        public init() {}
    }
}


public extension Applications.DailyMotion {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.DailyMotion.Action: PTExternalApplicationAction {
    
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
