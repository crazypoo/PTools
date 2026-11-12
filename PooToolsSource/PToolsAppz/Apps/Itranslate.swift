// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Itranslate: PTExternalApplication {
        
        public typealias ActionType = Applications.Itranslate.Action
        
        public let scheme = "itranslate:"
        public let fallbackURL = "http://itranslateapp.com/"
        public let appStoreId = "288113403"
        
        public init() {}
    }
}


public extension Applications.Itranslate {
    
    enum Action: Sendable {
        
        case open
        case translate(from: String, to: String, text: String)
    }
}


extension Applications.Itranslate.Action: PTExternalApplicationAction {
    
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
            
        case .translate(let from, let to, let text):
            return PTApplicationActionPaths(
                app: PTApplicationPath(
                    pathComponents: ["translate"],
                    queryParameters: [
                        "from": from,
                        "to": to,
                        "text": text
                    ]
                ),
                web: PTApplicationPath()
            )
        }
    }
}
