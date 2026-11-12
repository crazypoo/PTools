// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Epson: PTExternalApplication {
        
        public typealias ActionType = Applications.Epson.Action
        
        public let scheme = "com.epson.iPrint:"
        public let fallbackURL = "https://www.epson.com/cgi-bin/Store/jsp/epson-connect/mobile-printing/iprint-app.do"
        public let appStoreId = "326876192"
        
        public init() {}
    }
}


public extension Applications.Epson {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.Epson.Action: PTExternalApplicationAction {
    
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
