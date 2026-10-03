// English: Lock-protected Foundation matcher cache shared by rich-text value operations.
// Español: Caché de matchers de Foundation protegida por bloqueo y compartida por el valor rich-text.
// 中文：为富文本值操作提供加锁保护的 Foundation 匹配器缓存。

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
