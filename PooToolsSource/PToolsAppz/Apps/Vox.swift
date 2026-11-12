// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Vox: PTExternalApplication {
        
        public typealias ActionType = Applications.Vox.Action
        
        public let scheme = "com.coppertino.vox:"
        public let fallbackURL = "http://coppertino.com/vox/iphone"
        public let appStoreId = "916215494"
        
        public init() {}
    }
}


public extension Applications.Vox {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Vox.Action: PTExternalApplicationAction {
    
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
