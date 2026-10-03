//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

// English: Inspector font choices reuse the canonical PTFontRuntime discovery source.
// Español: Las opciones de fuente del Inspector reutilizan la fuente canónica PTFontRuntime.
// 中文：Inspector 字体选择复用统一的 PTFontRuntime 发现来源。
@MainActor
struct FontReference: Hashable, CustomStringConvertible {
    let rawValue: String

    let description: String

    let icon: UIImage?

    init(rawValue: String, description: String) {
        self.rawValue = rawValue
        self.description = description

        guard let font = Self.font(rawValue: rawValue, size: 18) else {
            icon = .none
            return
        }

        icon = "ABC"
            .image(withAttributes: [.font: font])?
            .withRenderingMode(.alwaysTemplate)
    }

    private func font(size: CGFloat) -> UIFont? {
        Self.font(rawValue: rawValue, size: size)
    }

    private static func font(rawValue: String, size: CGFloat) -> UIFont? {
        if rawValue == .systemFontFamilyName {
            return .systemFont(ofSize: size)
        }
        return UIFont(name: rawValue, size: size)
    }

    static let systemFontReference: FontReference = .init(
        rawValue: .systemFontFamilyName,
        description: .systemFontFamilyName
    )

    static func font(at index: Int, size: CGFloat) -> UIFont? {
        guard (0 ..< allCases.count).contains(index) else { return nil }

        let reference = allCases[index]

        return reference.font(size: size)
    }

    static func firstIndex(of fontName: String) -> Int? {
        FontReference.allCases.firstIndex { $0.rawValue == fontName } ?? FontReference.allCases.firstIndex(of: .systemFontReference)
    }

    static var allCases: [FontReference] {
        var references: [FontReference] = [.systemFontReference]
        references += PTFontRuntime.installedFonts
            .filter { $0.familyName != .systemFontFamilyName }
            .map { descriptor in
                let variation = variation(with: descriptor.postScriptName)
                let description = [descriptor.familyName, variation]
                    .compactMap { $0 }
                    .joined(separator: " ")
                return FontReference(rawValue: descriptor.postScriptName, description: description)
            }
        return references
    }

    private static func variation(with fontName: String) -> String? {
        let components = fontName.split(separator: "-")

        guard
            components.count > 1,
            let last = components.last
        else {
            return nil
        }

        return String(last)
            .camelCaseToWords()
    }
}
