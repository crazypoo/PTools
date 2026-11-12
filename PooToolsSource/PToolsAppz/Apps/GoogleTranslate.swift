// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct GoogleTranslate: PTExternalApplication {
        
        public typealias ActionType = Applications.GoogleTranslate.Action
        
        public let scheme = "googletranslate:"
        public let fallbackURL = "https://translate.google.com/about/intl/en_ALL/index.html"
        public let appStoreId = "414706506"
        
        public init() {}
    }
}


public extension Applications.GoogleTranslate {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.GoogleTranslate.Action: PTExternalApplicationAction {
    
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
