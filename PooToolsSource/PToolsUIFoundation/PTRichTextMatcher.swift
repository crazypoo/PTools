//
//  PTRichTextMatcher.swift
//  PToolsUIFoundation
//
//  English: Keep Foundation matcher caches separate from rich-text value construction.
//  Español: Mantiene las cachés de coincidencia de Foundation separadas de la construcción del valor.
//  中文：将 Foundation 匹配器缓存从富文本值构造中独立出来。
//

import Foundation

final class PTTextMatcherCache: @unchecked Sendable {
    private let lock = NSLock()
    private let regexCache = NSCache<NSString, NSRegularExpression>()
    private let detectorCache = NSCache<NSNumber, NSDataDetector>()

    init() {
        regexCache.countLimit = 64
        detectorCache.countLimit = 16
    }

    func regex(pattern: String, options: UInt32) -> NSRegularExpression? {
        let key = "\(options):\(pattern)" as NSString
        lock.lock()
        defer { lock.unlock() }

        if let cached = regexCache.object(forKey: key) {
            return cached
        }
        guard let compiled = try? NSRegularExpression(pattern: pattern,
                                                       options: NSRegularExpression.Options(rawValue: UInt(options))) else {
            return nil
        }
        regexCache.setObject(compiled, forKey: key)
        return compiled
    }

    func detector(for types: NSTextCheckingResult.CheckingType) -> NSDataDetector? {
        let key = NSNumber(value: types.rawValue)
        lock.lock()
        defer { lock.unlock() }

        if let cached = detectorCache.object(forKey: key) {
            return cached
        }
        guard let created = try? NSDataDetector(types: types.rawValue) else {
            return nil
        }
        detectorCache.setObject(created, forKey: key)
        return created
    }
}

