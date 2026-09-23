// English: Resolver order is primary symbol, catalog alias, fallback symbols, then nil.
// Español: El orden del resolver es símbolo principal, alias del catálogo, fallbacks y finalmente nil.
// 中文：解析顺序是主符号、目录别名、回退符号，最后返回 nil。

import UIKit

public enum PTSymbolResolver {
    public static func image(_ symbol: PTSymbol,
                             fallbacks: [PTSymbol] = [],
                             configuration: UIImage.Configuration? = nil,
                             variableValue: Double? = nil) -> UIImage? {
        let candidates = ([symbol] + fallbacks).flatMap(PTSymbolCatalog.resolvedNames(for:))
        let normalizedVariableValue = variableValue.map { min(max($0, 0), 1) }

        for name in candidates {
            let image: UIImage?
            if let normalizedVariableValue {
                image = UIImage(systemName: name,
                                variableValue: normalizedVariableValue,
                                configuration: configuration)
            }
            else {
                image = UIImage(systemName: name, withConfiguration: configuration)
            }
            if let image {
                return image
            }
        }

        PTSymbolDiagnostics.reportUnavailable(
            symbol: symbol,
            fallback: PTSymbolFallback(fallbacks),
            attemptedNames: candidates
        )
        return nil
    }
}
