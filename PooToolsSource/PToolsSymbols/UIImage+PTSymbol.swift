// English: UIKit adapters provide the typed initializer while keeping a non-crashing legacy bridge.
// Español: Los adaptadores UIKit ofrecen el inicializador tipado y mantienen un puente heredado sin crash.
// 中文：UIKit 适配层提供类型化初始化方法，并保留不会崩溃的旧调用桥接。

import UIKit

public extension UIImage {
    convenience init?(ptSymbol symbol: PTSymbol,
                      configuration: UIImage.Configuration? = nil) {
        guard let image = PTSymbolResolver.image(symbol, configuration: configuration) else {
            return nil
        }
        if let cgImage = image.cgImage {
            self.init(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        else if let data = image.pngData() {
            self.init(data: data)
        }
        else {
            return nil
        }
    }

    convenience init?(ptSymbol symbol: PTSymbol,
                      variableValue: Double,
                      configuration: UIImage.Configuration? = nil) {
        guard let image = PTSymbolResolver.image(symbol,
                                                 configuration: configuration,
                                                 variableValue: variableValue) else {
            return nil
        }
        if let cgImage = image.cgImage {
            self.init(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        else if let data = image.pngData() {
            self.init(data: data)
        }
        else {
            return nil
        }
    }

    static func pt_symbol(_ symbol: PTSymbol,
                          fallback: PTSymbol? = nil,
                          configuration: UIImage.Configuration? = nil) -> UIImage? {
        PTSymbolResolver.image(symbol,
                               fallbacks: fallback.map { [$0] } ?? [],
                               configuration: configuration)
    }

    static func pt_symbol(_ symbol: PTSymbol,
                          fallbacks: [PTSymbol],
                          variableValue: Double? = nil,
                          configuration: UIImage.Configuration? = nil) -> UIImage? {
        PTSymbolResolver.image(symbol,
                               fallbacks: fallbacks,
                               configuration: configuration,
                               variableValue: variableValue)
    }

    // English: This bridge keeps existing PTools source compiling while new code should prefer the failable typed API.
    // Español: Este puente mantiene compilado el código existente de PTools; el código nuevo debe preferir la API tipada failable.
    // 中文：这个桥接保持现有 PTools 源码兼容，新代码应优先使用可失败的类型化 API。
    convenience init(_ symbol: PTSymbol) {
        if let image = PTSymbolResolver.image(symbol), let cgImage = image.cgImage {
            self.init(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        else {
            self.init()
        }
    }

    convenience init(_ symbol: PTSymbol, pointSize: CGFloat, weight: UIImage.SymbolWeight) {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        if let image = PTSymbolResolver.image(symbol, configuration: configuration), let cgImage = image.cgImage {
            self.init(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        else {
            self.init()
        }
    }

    convenience init(_ symbol: PTSymbol, font: UIFont) {
        let configuration = UIImage.SymbolConfiguration(font: font)
        if let image = PTSymbolResolver.image(symbol, configuration: configuration), let cgImage = image.cgImage {
            self.init(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        else {
            self.init()
        }
    }
}
