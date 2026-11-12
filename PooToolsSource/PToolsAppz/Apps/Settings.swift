// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

#if canImport(UIKit)
import UIKit

public extension Applications {
    
    struct AppSettings: PTExternalApplication {
        
        public typealias ActionType = Applications.AppSettings.Action

        public let scheme = UIApplication.openSettingsURLString
        public let fallbackURL = ""
        public let appStoreId = ""
        
        public init() {}
    }
}


public extension Applications.AppSettings {

    enum Action: Sendable {
        case open
    }
}

extension Applications.AppSettings.Action: PTExternalApplicationAction {
    
    public var paths: PTApplicationActionPaths {
        
        switch self {
        case .open:
            return PTApplicationActionPaths()
        }
    }
}
#endif
