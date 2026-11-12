// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct RoboForm: PTExternalApplication {
        
        public typealias ActionType = Applications.RoboForm.Action
        
        public let scheme = "roboform:"
        public let fallbackURL = "http://www.roboform.com/for-iphone-ipad-ios"
        public let appStoreId = "331787573"
        
        public init() {}
    }
}


public extension Applications.RoboForm {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.RoboForm.Action: PTExternalApplicationAction {
    
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
