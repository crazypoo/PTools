// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct ScannerPro: PTExternalApplication {
        
        public typealias ActionType = Applications.ScannerPro.Action
        
        public let scheme = "spprint:"
        public let fallbackURL = "https://readdle.com/products/scannerpro/"
        public let appStoreId = "333710667"
        
        public init() {}
    }
}


public extension Applications.ScannerPro {
    
    enum Action: Sendable {
        case open
    }
}

extension Applications.ScannerPro.Action: PTExternalApplicationAction {
    
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
