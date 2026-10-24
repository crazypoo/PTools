// English: Build a display copy and source map for opt-in fragment-level rich-text limits.
// Español: Construye una copia visible y un mapa de origen para los límites opt-in de fragmentos.
// 中文：为显式启用的片段级富文本限行生成显示副本和原文映射。

import CoreText
import Foundation
import UIKit

@MainActor
public struct PTTextFlowLayoutResult {
    public let renderedText: NSAttributedString
    public let sourceMap: [NSRange?]
    public let truncatedFragmentRanges: [NSRange]
    public let lineCount: Int
    public let constrainedWidth: CGFloat

    public init(renderedText: NSAttributedString,
                sourceMap: [NSRange?],
                truncatedFragmentRanges: [NSRange],
                lineCount: Int,
                constrainedWidth: CGFloat) {
        self.renderedText = renderedText
        self.sourceMap = sourceMap
        self.truncatedFragmentRanges = truncatedFragmentRanges
        self.lineCount = lineCount
        self.constrainedWidth = constrainedWidth
    }

    public func sourceRange(for displayedRange: NSRange) -> NSRange? {
        guard displayedRange.location >= 0,
              displayedRange.length > 0,
              NSMaxRange(displayedRange) <= sourceMap.count else { return nil }
        let mapped = sourceMap[displayedRange.location..<NSMaxRange(displayedRange)].compactMap { $0 }
        guard let first = mapped.map(\.location).min(),
              let last = mapped.map({ NSMaxRange($0) }).max() else { return nil }
        return NSRange(location: first, length: max(0, last - first))
    }

    #if DEBUG
    public func diagnosticReport(for richText: PTRichText) -> String {
        let fragments = richText.textFragmentRuns.map {
            "range=\(NSStringFromRange($0.range)) maxLines=\($0.layout.maxLines) mode=\($0.layout.resolvedLineBreakMode.rawValue) keepAttachment=\($0.layout.keepWithNextAttachment)"
        }
        return [
            "width=\(constrainedWidth)",
            "lineCount=\(lineCount)",
            "renderedLength=\(renderedText.length)",
            "truncated=\(truncatedFragmentRanges.map(NSStringFromRange).joined(separator: ","))",
            "fragments=\(fragments.joined(separator: ";"))"
        ].joined(separator: "\n")
    }
    #endif
}

@MainActor
public enum PTRichTextFlowLayoutEngine {
    public static func layout(_ richText: PTRichText,
                              width: CGFloat,
                              hostNumberOfLines: Int = 0) -> PTTextFlowLayoutResult {
        let safeWidth = width.isFinite ? max(0, width) : 0
        guard safeWidth > 0, richText.value.length > 0 else {
            return PTTextFlowLayoutResult(renderedText: richText.value,
                                          sourceMap: Array(repeating: nil, count: richText.value.length),
                                          truncatedFragmentRanges: [],
                                          lineCount: 0,
                                          constrainedWidth: safeWidth)
        }

        let builder = PTTextFlowDisplayBuilder(width: safeWidth)
        let source = richText.value
        let fragments = richText.textFragmentRuns.sorted { lhs, rhs in
            lhs.location == rhs.location ? lhs.length < rhs.length : lhs.location < rhs.location
        }
        var cursor = 0
        var truncated: [NSRange] = []

        for fragment in fragments {
            guard fragment.location >= cursor, fragment.location < source.length else { continue }
            if cursor < fragment.location {
                process(source: source,
                        range: NSRange(location: cursor, length: fragment.location - cursor),
                        spec: nil,
                        builder: builder,
                        truncated: &truncated)
            }
            let end = min(source.length, NSMaxRange(fragment.range))
            process(source: source,
                    range: NSRange(location: fragment.location, length: end - fragment.location),
                    spec: fragment.layout,
                    builder: builder,
                    truncated: &truncated)
            cursor = end
        }
        if cursor < source.length {
            process(source: source,
                    range: NSRange(location: cursor, length: source.length - cursor),
                    spec: nil,
                    builder: builder,
                    truncated: &truncated)
        }

        var rendered: NSAttributedString = builder.value
        if hostNumberOfLines > 0 {
            rendered = applyHostLineLimit(rendered,
                                          numberOfLines: hostNumberOfLines,
                                          width: safeWidth)
        }
        let lineCount = lineCount(of: rendered, width: safeWidth)
        return PTTextFlowLayoutResult(renderedText: rendered,
                                      sourceMap: Array(builder.sourceMap.prefix(rendered.length)),
                                      truncatedFragmentRanges: truncated,
                                      lineCount: lineCount,
                                      constrainedWidth: safeWidth)
    }

    private static func process(source: NSAttributedString,
                                range: NSRange,
                                spec: PTTextFragmentLayoutSpec?,
                                builder: PTTextFlowDisplayBuilder,
                                truncated: inout [NSRange]) {
        guard range.length > 0 else { return }
        let maxLines = spec?.maxLines ?? 0
        let mode = spec?.resolvedLineBreakMode ?? .byWordWrapping
        var start = range.location
        var usedLines = 1

        while start < NSMaxRange(range) {
            let newline = nextNewline(in: source, from: start, before: NSMaxRange(range))
            let textEnd = newline ?? NSMaxRange(range)
            if start == textEnd {
                builder.append(source: source, range: NSRange(location: start, length: 1))
                builder.finishLine()
                usedLines += 1
                start += 1
                continue
            }

            let available = builder.remainingWidth
            let suggested = suggestedBreak(in: source,
                                           range: NSRange(location: start, length: textEnd - start),
                                           width: available,
                                           mode: mode)
            let candidateEnd = min(textEnd, start + max(1, suggested))
            let hasMoreInFragment = candidateEnd < NSMaxRange(range) || newline != nil
            if maxLines > 0, usedLines >= maxLines, hasMoreInFragment {
                let reserved = spec?.keepWithNextAttachment == true
                    ? builder.nextAttachmentReservation(in: source, after: range)
                    : 0
                let truncationWidth = max(1, available - reserved)
                switch mode {
                case .byTruncatingHead, .byTruncatingMiddle, .byTruncatingTail:
                    builder.appendTruncated(source: source,
                                            range: NSRange(location: start, length: NSMaxRange(range) - start),
                                            width: truncationWidth,
                                            mode: mode)
                case .byWordWrapping, .byCharWrapping, .byClipping:
                    let clippedEnd = fitEnd(source: source,
                                            range: NSRange(location: start, length: NSMaxRange(range) - start),
                                            width: truncationWidth,
                                            builder: builder,
                                            mode: mode)
                    if clippedEnd > start {
                        builder.append(source: source,
                                       range: NSRange(location: start, length: clippedEnd - start))
                    }
                }
                truncated.append(range)
                return
            }

            builder.append(source: source,
                           range: NSRange(location: start, length: candidateEnd - start))
            start = candidateEnd
            if start < textEnd {
                builder.finishLine()
                usedLines += 1
            }

            if let newline, start == newline {
                builder.append(source: source, range: NSRange(location: newline, length: 1))
                builder.finishLine()
                usedLines += 1
                start += 1
            }
        }
    }

    private static func nextNewline(in source: NSAttributedString,
                                    from start: Int,
                                    before end: Int) -> Int? {
        let substring = source.string as NSString
        let searchRange = NSRange(location: start, length: end - start)
        let result = substring.range(of: "\n", options: [], range: searchRange)
        return result.location == NSNotFound ? nil : result.location
    }

    private static func suggestedBreak(in source: NSAttributedString,
                                      range: NSRange,
                                      width: CGFloat,
                                      mode: PTTextFragmentLineBreakMode) -> Int {
        guard range.length > 0 else { return 0 }
        guard width > 0 else { return 1 }
        let input = source.attributedSubstring(from: range)
        let typesetter = CTTypesetterCreateWithAttributedString(input as CFAttributedString)
        let value: CFIndex
        switch mode {
        case .byCharWrapping:
            value = CTTypesetterSuggestClusterBreak(typesetter, 0, Double(width))
        case .byClipping:
            value = CTTypesetterSuggestClusterBreak(typesetter, 0, Double(width))
        default:
            value = CTTypesetterSuggestLineBreak(typesetter, 0, Double(width))
        }
        return max(1, min(range.length, value))
    }

    private static func fitEnd(source: NSAttributedString,
                                range: NSRange,
                                width: CGFloat,
                                builder: PTTextFlowDisplayBuilder,
                                mode: PTTextFragmentLineBreakMode) -> Int {
        guard range.length > 0 else { return range.location }
        var end = range.location
        while end < NSMaxRange(range) {
            let boundary = source.string.nsComposedCharacterRange(at: end)
            let nextEnd = min(NSMaxRange(range), NSMaxRange(boundary))
            let candidate = source.attributedSubstring(from: NSRange(location: range.location,
                                                                      length: nextEnd - range.location))
            if builder.width(of: candidate) > width { break }
            end = nextEnd
            if mode == .byClipping { continue }
            let suggested = suggestedBreak(in: source,
                                           range: NSRange(location: range.location,
                                                          length: nextEnd - range.location),
                                           width: width,
                                           mode: mode)
            if suggested < nextEnd - range.location { break }
        }
        return end
    }

    private static func lineCount(of value: NSAttributedString, width: CGFloat) -> Int {
        guard value.length > 0, width > 0 else { return 0 }
        let typesetter = CTTypesetterCreateWithAttributedString(value as CFAttributedString)
        var index: CFIndex = 0
        var count = 0
        while index < value.length {
            let length = CTTypesetterSuggestLineBreak(typesetter, index, Double(width))
            guard length > 0 else { break }
            index += length
            count += 1
        }
        return count
    }

    private static func applyHostLineLimit(_ value: NSAttributedString,
                                           numberOfLines: Int,
                                           width: CGFloat) -> NSAttributedString {
        guard numberOfLines > 0 else { return value }
        let typesetter = CTTypesetterCreateWithAttributedString(value as CFAttributedString)
        var index: CFIndex = 0
        var line = 0
        var end = value.length
        while index < value.length, line < numberOfLines {
            let length = CTTypesetterSuggestLineBreak(typesetter, index, Double(width))
            guard length > 0 else { break }
            index += length
            line += 1
            end = index
        }
        guard end < value.length else { return value }
        return value.attributedSubstring(from: NSRange(location: 0, length: end))
    }
}

@MainActor
private final class PTTextFlowDisplayBuilder {
    let width: CGFloat
    private(set) var value = NSMutableAttributedString()
    private(set) var sourceMap: [NSRange?] = []
    private var currentLine = NSMutableAttributedString()

    init(width: CGFloat) {
        self.width = width
    }

    var remainingWidth: CGFloat {
        max(1, width - width(of: currentLine))
    }

    func width(of value: NSAttributedString) -> CGFloat {
        guard value.length > 0 else { return 0 }
        let line = CTLineCreateWithAttributedString(value as CFAttributedString)
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }

    func append(source: NSAttributedString, range: NSRange) {
        guard range.length > 0 else { return }
        let piece = source.attributedSubstring(from: range)
        let start = value.length
        value.append(piece)
        currentLine.append(piece)
        sourceMap.append(contentsOf: (0..<piece.length).map {
            NSRange(location: range.location + $0, length: 1)
        })
        _ = start
    }

    func appendTruncated(source: NSAttributedString,
                         range: NSRange,
                         width: CGFloat,
                         mode: PTTextFragmentLineBreakMode) {
        guard range.length > 0 else { return }
        let ellipsis = NSMutableAttributedString(string: "…",
                                                  attributes: source.attributes(at: range.location,
                                                                                effectiveRange: nil))
        ellipsis.removeAttribute(PTRichText.actionAttributeKey,
                                 range: NSRange(location: 0, length: ellipsis.length))
        let full = source.attributedSubstring(from: range)
        if self.width(of: full) <= width {
            append(source: source, range: range)
            return
        }

        switch mode {
        case .byTruncatingHead:
            let suffix = fittingSuffix(source: source, range: range, ellipsis: ellipsis, width: width)
            append(ellipsis: ellipsis)
            append(source: source, range: suffix)
        case .byTruncatingMiddle:
            let pieces = fittingMiddle(source: source, range: range, ellipsis: ellipsis, width: width)
            append(source: source, range: pieces.prefix)
            append(ellipsis: ellipsis)
            append(source: source, range: pieces.suffix)
        case .byTruncatingTail, .byWordWrapping, .byCharWrapping, .byClipping:
            let prefix = fittingPrefix(source: source, range: range, ellipsis: ellipsis, width: width)
            append(source: source, range: prefix)
            append(ellipsis: ellipsis)
        }
    }

    func finishLine() {
        currentLine = NSMutableAttributedString()
    }

    func nextAttachmentReservation(in source: NSAttributedString, after range: NSRange) -> CGFloat {
        var index = NSMaxRange(range)
        while index < source.length,
              source.string.nsComposedCharacterRange(at: index).length == 1,
              source.string.isWhitespace(atUTF16Offset: index) {
            index += 1
        }
        guard index < source.length,
              let attachment = source.attribute(.attachment, at: index, effectiveRange: nil) as? NSTextAttachment else {
            return 0
        }
        return max(0, attachment.bounds.width) + (index > NSMaxRange(range) ? width(of: source.attributedSubstring(from: NSRange(location: NSMaxRange(range), length: index - NSMaxRange(range)))) : 0)
    }

    private func append(ellipsis: NSAttributedString) {
        value.append(ellipsis)
        currentLine.append(ellipsis)
        sourceMap.append(nil)
    }

    private func appending(_ lhs: NSAttributedString, _ rhs: NSAttributedString) -> NSAttributedString {
        let value = NSMutableAttributedString(attributedString: lhs)
        value.append(rhs)
        return value
    }

    private func fittingPrefix(source: NSAttributedString,
                               range: NSRange,
                               ellipsis: NSAttributedString,
                               width: CGFloat) -> NSRange {
        var end = range.location
        while end < NSMaxRange(range) {
            let composed = source.string.nsComposedCharacterRange(at: end)
            let candidateEnd = min(NSMaxRange(range), NSMaxRange(composed))
            let prefix = source.attributedSubstring(from: NSRange(location: range.location,
                                                                    length: candidateEnd - range.location))
            if self.width(of: appending(prefix, ellipsis)) > width { break }
            end = candidateEnd
        }
        return NSRange(location: range.location, length: max(0, end - range.location))
    }

    private func fittingSuffix(source: NSAttributedString,
                               range: NSRange,
                               ellipsis: NSAttributedString,
                               width: CGFloat) -> NSRange {
        var start = NSMaxRange(range)
        while start > range.location {
            let composed = source.string.nsComposedCharacterRange(at: start - 1)
            let candidateStart = max(range.location, composed.location)
            let suffix = source.attributedSubstring(from: NSRange(location: candidateStart,
                                                                   length: NSMaxRange(range) - candidateStart))
            if self.width(of: appending(ellipsis, suffix)) > width { break }
            start = candidateStart
        }
        return NSRange(location: start, length: NSMaxRange(range) - start)
    }

    private func fittingMiddle(source: NSAttributedString,
                               range: NSRange,
                               ellipsis: NSAttributedString,
                               width: CGFloat) -> (prefix: NSRange, suffix: NSRange) {
        var prefixEnd = range.location
        var suffixStart = NSMaxRange(range)
        while prefixEnd < suffixStart {
            let prefixComposed = source.string.nsComposedCharacterRange(at: prefixEnd)
            let suffixComposed = source.string.nsComposedCharacterRange(at: suffixStart - 1)
            let nextPrefix = min(suffixStart, NSMaxRange(prefixComposed))
            let nextSuffix = max(prefixEnd, suffixComposed.location)
            let prefix = source.attributedSubstring(from: NSRange(location: range.location,
                                                                  length: nextPrefix - range.location))
            let suffix = source.attributedSubstring(from: NSRange(location: nextSuffix,
                                                                  length: NSMaxRange(range) - nextSuffix))
            if self.width(of: appending(prefix, appending(ellipsis, suffix))) > width {
                break
            }
            prefixEnd = nextPrefix
            suffixStart = nextSuffix
        }
        return (NSRange(location: range.location, length: prefixEnd - range.location),
                NSRange(location: suffixStart, length: NSMaxRange(range) - suffixStart))
    }
}

private extension String {
    func nsComposedCharacterRange(at utf16Offset: Int) -> NSRange {
        let value = self as NSString
        guard utf16Offset >= 0, utf16Offset < value.length else {
            return NSRange(location: max(0, min(utf16Offset, value.length)), length: 0)
        }
        return value.rangeOfComposedCharacterSequence(at: utf16Offset)
    }

    func isWhitespace(atUTF16Offset utf16Offset: Int) -> Bool {
        let offset = max(0, min(utf16Offset, utf16.count))
        let index = String.Index(utf16Offset: offset, in: self)
        guard index < endIndex else { return false }
        return self[index...].first?.isWhitespace == true
    }
}
