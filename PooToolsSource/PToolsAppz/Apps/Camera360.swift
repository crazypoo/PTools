// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Camera360: PTExternalApplication {
        
        public typealias ActionType = Applications.Camera360.Action
        
        public let scheme = "camera360:"
        public let fallbackURL = "https://www.camera360.com/production/?production=camera360&platform=ios"
        public let appStoreId = "443354861"
        
        public init() {}
    }
}


public extension Applications.Camera360 {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Camera360.Action: PTExternalApplicationAction {
    
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
