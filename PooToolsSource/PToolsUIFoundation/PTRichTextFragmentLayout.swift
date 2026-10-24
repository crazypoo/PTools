// English: Value-only fragment layout contracts shared by the rich-text model and UIKit flow host.
// Español: Contratos de layout de fragmentos basados en valores compartidos por el modelo y el host UIKit.
// 中文：富文本值模型与 UIKit Flow 宿主共享的值类型片段布局契约。

import Foundation
import UIKit

public enum PTTextFragmentLineBreakMode: Int, Codable, Hashable, Sendable {
    case byWordWrapping = 0
    case byCharWrapping = 1
    case byClipping = 2
    case byTruncatingHead = 3
    case byTruncatingTail = 4
    case byTruncatingMiddle = 5
}

public struct PTTextFragmentLayoutSpec: Codable, Hashable, Sendable {
    public let maxLines: Int
    public let lineBreakMode: PTTextFragmentLineBreakMode?
    public let keepWithNextAttachment: Bool

    public init(maxLines: Int = 0,
                lineBreakMode: PTTextFragmentLineBreakMode? = nil,
                keepWithNextAttachment: Bool = false) {
        self.maxLines = max(0, maxLines)
        self.lineBreakMode = lineBreakMode
        self.keepWithNextAttachment = keepWithNextAttachment
    }

    public init(maxLines: Int = 0,
                lineBreakMode: NSLineBreakMode?,
                keepWithNextAttachment: Bool = false) {
        self.init(maxLines: maxLines,
                  lineBreakMode: lineBreakMode.map(PTTextFragmentLineBreakMode.init),
                  keepWithNextAttachment: keepWithNextAttachment)
    }

    public var resolvedLineBreakMode: PTTextFragmentLineBreakMode {
        lineBreakMode ?? (maxLines > 0 ? .byTruncatingTail : .byWordWrapping)
    }

    public var nsLineBreakMode: NSLineBreakMode {
        resolvedLineBreakMode.nsValue
    }
}

public struct PTTextFragmentRun: Codable, Equatable, Hashable, Sendable {
    public let location: Int
    public let length: Int
    public let layout: PTTextFragmentLayoutSpec

    public init(range: NSRange, layout: PTTextFragmentLayoutSpec) {
        self.location = max(0, range.location)
        self.length = max(0, range.length)
        self.layout = layout
    }

    public init(location: Int, length: Int, layout: PTTextFragmentLayoutSpec) {
        self.init(range: NSRange(location: location, length: length), layout: layout)
    }

    public var range: NSRange {
        NSRange(location: location, length: length)
    }
}

extension PTTextFragmentLineBreakMode {
    init(_ value: NSLineBreakMode) {
        switch value {
        case .byCharWrapping: self = .byCharWrapping
        case .byClipping: self = .byClipping
        case .byTruncatingHead: self = .byTruncatingHead
        case .byTruncatingMiddle: self = .byTruncatingMiddle
        case .byTruncatingTail: self = .byTruncatingTail
        case .byWordWrapping: self = .byWordWrapping
        @unknown default: self = .byWordWrapping
        }
    }

    var nsValue: NSLineBreakMode {
        switch self {
        case .byWordWrapping: .byWordWrapping
        case .byCharWrapping: .byCharWrapping
        case .byClipping: .byClipping
        case .byTruncatingHead: .byTruncatingHead
        case .byTruncatingTail: .byTruncatingTail
        case .byTruncatingMiddle: .byTruncatingMiddle
        }
    }
}

struct PTTextFragmentLayoutOverrides: Equatable, Sendable {
    var maxLines: Int?
    var lineBreakMode: PTTextFragmentLineBreakMode?
    var keepWithNextAttachment: Bool?

    var isMeaningful: Bool {
        maxLines != nil || lineBreakMode != nil || keepWithNextAttachment != nil
    }

    func resolved(defaults: PTTextFragmentLayoutSpec = .init()) -> PTTextFragmentLayoutSpec {
        PTTextFragmentLayoutSpec(maxLines: maxLines ?? defaults.maxLines,
                                 lineBreakMode: lineBreakMode ?? defaults.lineBreakMode,
                                 keepWithNextAttachment: keepWithNextAttachment ?? defaults.keepWithNextAttachment)
    }
}

extension PTTextFragmentLayoutSpec {
    var overrides: PTTextFragmentLayoutOverrides {
        PTTextFragmentLayoutOverrides(maxLines: maxLines,
                                      lineBreakMode: lineBreakMode,
                                      keepWithNextAttachment: keepWithNextAttachment)
    }
}

extension PTTextFragmentLayoutSpec {
    init?(dictionary: NSDictionary) {
        guard let maxLines = dictionary["maxLines"] as? NSNumber else { return nil }
        let mode = (dictionary["lineBreakMode"] as? NSNumber).flatMap {
            PTTextFragmentLineBreakMode(rawValue: $0.intValue)
        }
        let keep = (dictionary["keepWithNextAttachment"] as? NSNumber)?.boolValue ?? false
        self.init(maxLines: maxLines.intValue,
                  lineBreakMode: mode,
                  keepWithNextAttachment: keep)
    }

    var dictionary: NSDictionary {
        let dictionary = NSMutableDictionary()
        dictionary["maxLines"] = maxLines
        if let lineBreakMode {
            dictionary["lineBreakMode"] = lineBreakMode.rawValue
        }
        dictionary["keepWithNextAttachment"] = keepWithNextAttachment
        return dictionary.copy() as? NSDictionary ?? NSDictionary()
    }
}

extension PTTextFragmentRun {
    init?(dictionary: NSDictionary) {
        guard let location = dictionary["location"] as? NSNumber,
              let length = dictionary["length"] as? NSNumber,
              let specDictionary = dictionary["layout"] as? NSDictionary,
              let layout = PTTextFragmentLayoutSpec(dictionary: specDictionary) else {
            return nil
        }
        self.init(location: location.intValue, length: length.intValue, layout: layout)
    }

    var dictionary: NSDictionary {
        let dictionary = NSMutableDictionary()
        dictionary["location"] = location
        dictionary["length"] = length
        dictionary["layout"] = layout.dictionary
        return dictionary.copy() as? NSDictionary ?? NSDictionary()
    }
}
