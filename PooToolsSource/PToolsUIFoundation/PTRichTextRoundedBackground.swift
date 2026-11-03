// English: Opt-in rounded decorations for inline PTRichText ranges.
// Español: Decoraciones redondeadas opcionales para segmentos de PTRichText.
// 中文：为 PTRichText 局部文本提供显式启用的圆角背景绘制。

import Foundation
import UIKit

// English: Store resolved light/dark RGBA components, never a non-Sendable UIColor, in AttributedString.
struct PTTextBackgroundRGBA: Codable, Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(_ color: UIColor, style: UIUserInterfaceStyle) {
        let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1
        if !resolved.getRed(&r, green: &g, blue: &b, alpha: &a) {
            var white: CGFloat = 0
            if resolved.getWhite(&white, alpha: &a) {
                r = white
                g = white
                b = white
            }
        }
        red = Double(r)
        green = Double(g)
        blue = Double(b)
        alpha = Double(a)
    }

    func uiColor() -> UIColor {
        UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}

struct PTTextBackgroundColorPair: Codable, Hashable, Sendable {
    let light: PTTextBackgroundRGBA
    let dark: PTTextBackgroundRGBA

    init(_ color: UIColor) {
        light = PTTextBackgroundRGBA(color, style: .light)
        dark = PTTextBackgroundRGBA(color, style: .dark)
    }

    func resolve(for traitCollection: UITraitCollection) -> UIColor {
        (traitCollection.userInterfaceStyle == .dark ? dark : light).uiColor()
    }
}

/// Controls whether the requested radius is fixed in points or follows the
/// actual painted pill size. The fixed default preserves existing call sites.
public enum PTTextRoundedBackgroundCornerMode: String, Codable, Hashable, Sendable {
    case fixed
    case capsule
}

// English: Primitive-only value survives Foundation.AttributedString copying and Swift 6 isolation.
public struct PTTextRoundedBackgroundSpec: Codable, Hashable, Sendable {
    let fill: PTTextBackgroundColorPair
    let stroke: PTTextBackgroundColorPair?
    let radius: Double
    // Nil decodes styles emitted before the capsule option was introduced.
    let cornerMode: PTTextRoundedBackgroundCornerMode?
    let top: Double
    let left: Double
    let bottom: Double
    let right: Double
    let strokeWidth: Double
    // Optional for backward-compatible decoding of values created by PR #40.
    let hitTop: Double?
    let hitLeft: Double?
    let hitBottom: Double?
    let hitRight: Double?
    // Optional so previously encoded rounded backgrounds remain readable.
    let leadingSpacing: Double?
    let trailingSpacing: Double?

    init(color: UIColor,
         cornerRadius: CGFloat,
         cornerMode: PTTextRoundedBackgroundCornerMode = .fixed,
         insets: UIEdgeInsets,
         borderColor: UIColor?,
         borderWidth: CGFloat,
         hitTestInsets: UIEdgeInsets = .zero,
         leadingSpacing: CGFloat = 0,
         trailingSpacing: CGFloat = 0) {
        fill = PTTextBackgroundColorPair(color)
        stroke = borderColor.map(PTTextBackgroundColorPair.init)
        radius = Double(max(0, cornerRadius.isFinite ? cornerRadius : 0))
        self.cornerMode = cornerMode
        top = Double(max(0, insets.top.isFinite ? insets.top : 0))
        left = Double(max(0, insets.left.isFinite ? insets.left : 0))
        bottom = Double(max(0, insets.bottom.isFinite ? insets.bottom : 0))
        right = Double(max(0, insets.right.isFinite ? insets.right : 0))
        strokeWidth = Double(max(0, borderWidth.isFinite ? borderWidth : 0))
        hitTop = Double(max(0, hitTestInsets.top.isFinite ? hitTestInsets.top : 0))
        hitLeft = Double(max(0, hitTestInsets.left.isFinite ? hitTestInsets.left : 0))
        hitBottom = Double(max(0, hitTestInsets.bottom.isFinite ? hitTestInsets.bottom : 0))
        hitRight = Double(max(0, hitTestInsets.right.isFinite ? hitTestInsets.right : 0))
        self.leadingSpacing = Double(max(0, leadingSpacing.isFinite ? leadingSpacing : 0))
        self.trailingSpacing = Double(max(0, trailingSpacing.isFinite ? trailingSpacing : 0))
    }

    var hasExternalSpacing: Bool {
        (leadingSpacing ?? 0) > 0 || (trailingSpacing ?? 0) > 0
    }

    var hitInsets: UIEdgeInsets {
        UIEdgeInsets(top: CGFloat(hitTop ?? 0),
                     left: CGFloat(hitLeft ?? 0),
                     bottom: CGFloat(hitBottom ?? 0),
                     right: CGFloat(hitRight ?? 0))
    }

    var encoded: Data {
        // This concrete Codable value has no failable fields.
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    static func decode(_ value: Any?) -> Self? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

public struct PTTextRoundedBackgroundAttribute: CodableAttributedStringKey {
    public typealias Value = PTTextRoundedBackgroundSpec
    public static let name = "PTools.roundedBackgroundStyle"

    public init() {}
}

@MainActor
struct PTTextRoundedBackgroundSegment {
    let rect: CGRect
    let characterRange: NSRange
    let style: PTTextRoundedBackgroundSpec
}

@MainActor
enum PTRichTextRoundedBackgroundRenderer {
    private static func hasRoundedBackground(in text: NSAttributedString) -> Bool {
        guard text.length > 0 else { return false }
        var found = false
        text.enumerateAttribute(PTRichText.roundedBackgroundAttributeKey,
                                in: NSRange(location: 0, length: text.length),
                                options: []) { value, _, stop in
            if PTTextRoundedBackgroundSpec.decode(value) != nil {
                found = true
                stop.pointee = true
            }
        }
        return found
    }

    // Kerning at the boundaries provides a real layout gap without inserting
    // whitespace/attachment characters (which would change Action UTF-16 ranges).
    // Added leading/trailing distance is measured outside the painted background:
    // reserve the requested margin plus the corresponding background inset.
    static func textWithExternalSpacing(_ text: NSAttributedString) -> NSAttributedString {
        guard text.length > 0 else { return text }
        let full = NSRange(location: 0, length: text.length)
        let source = text.string as NSString
        var adjustments: [Int: (range: NSRange, value: CGFloat)] = [:]
        var processed: [NSRange] = []

        text.enumerateAttribute(PTRichText.roundedBackgroundAttributeKey,
                                in: full,
                                options: []) { rawStyle, range, _ in
            guard let style = PTTextRoundedBackgroundSpec.decode(rawStyle),
                  style.hasExternalSpacing,
                  text.attribute(PTRichText.externalSpacingAppliedAttributeKey,
                                 at: range.location,
                                 effectiveRange: nil) as? Bool != true else { return }
            processed.append(range)
            // Logical leading/trailing follows string order; RTL text layout
            // still uses UIKit's own writing direction and line breaking.
            if let before = Self.previousCharacterRange(before: range.location, in: source),
               (style.leadingSpacing ?? 0) > 0 {
                let addition = CGFloat((style.leadingSpacing ?? 0) + style.left)
                let key = before.location
                let previous = adjustments[key]?.value ?? 0
                adjustments[key] = (before, previous + addition)
            }
            if let after = Self.lastCharacterRange(before: NSMaxRange(range), in: source),
               NSMaxRange(range) < source.length,
               !Self.isHardBreak(at: NSMaxRange(range), in: source),
               (style.trailingSpacing ?? 0) > 0 {
                let addition = CGFloat((style.trailingSpacing ?? 0) + style.right)
                let key = after.location
                let previous = adjustments[key]?.value ?? 0
                adjustments[key] = (after, previous + addition)
            }
        }
        guard !processed.isEmpty else { return text }
        let spaced = NSMutableAttributedString(attributedString: text)
        for (_, entry) in adjustments {
            let existing = (text.attribute(.kern, at: entry.range.location,
                                            effectiveRange: nil) as? NSNumber)?.doubleValue ?? 0
            spaced.addAttribute(.kern,
                                value: existing + Double(entry.value),
                                range: entry.range)
        }
        for range in processed {
            spaced.addAttribute(PTRichText.externalSpacingAppliedAttributeKey,
                                value: true,
                                range: range)
        }
        return spaced
    }

    private static func previousCharacterRange(before index: Int,
                                               in string: NSString) -> NSRange? {
        guard index > 0, index <= string.length else { return nil }
        let range = string.rangeOfComposedCharacterSequence(at: index - 1)
        guard NSMaxRange(range) == index,
              !isHardBreak(at: range.location, in: string),
              string.substring(with: range) != "\u{FFFC}" else { return nil }
        return range
    }

    private static func lastCharacterRange(before index: Int,
                                           in string: NSString) -> NSRange? {
        previousCharacterRange(before: index, in: string)
    }

    private static func isHardBreak(at index: Int, in string: NSString) -> Bool {
        guard index >= 0, index < string.length else { return true }
        let character = string.character(at: index)
        return character == 10 || character == 13 || character == 0x2028 || character == 0x2029
    }

    // UILabel and UITextView otherwise paint NSAttributedString.backgroundColor as a square.
    static func textForDecoratedHost(_ text: NSAttributedString) -> NSAttributedString {
        guard text.length > 0 else { return text }
        let spacedText = textWithExternalSpacing(text)
        var ranges: [NSRange] = []
        spacedText.enumerateAttribute(PTRichText.roundedBackgroundAttributeKey,
                                in: NSRange(location: 0, length: spacedText.length),
                                options: []) { value, range, _ in
            if PTTextRoundedBackgroundSpec.decode(value) != nil {
                ranges.append(range)
            }
        }
        guard !ranges.isEmpty else { return spacedText }
        let result = NSMutableAttributedString(attributedString: spacedText)
        for range in ranges {
            result.removeAttribute(.backgroundColor, range: range)
        }
        return result
    }

    static func draw(on label: UILabel, in rect: CGRect) {
        guard let text = label.attributedText, hasRoundedBackground(in: text) else { return }
        // UILabel already passes its text drawing rect into drawText(in:).
        // Re-centering that rect would shift decoration away from rendered glyphs.
        let textRect = rect
        guard textRect.width > 0, textRect.height > 0 else { return }
        let segments = layoutSegments(in: text,
                                      size: textRect.size,
                                      font: label.font,
                                      alignment: label.textAlignment,
                                      numberOfLines: label.numberOfLines,
                                      lineBreakMode: label.lineBreakMode)
        paint(segments, origin: textRect.origin, clipping: label.bounds, traitCollection: label.traitCollection)
    }

    static func draw(on textView: UITextView) {
        guard let text = textView.attributedText, hasRoundedBackground(in: text) else { return }
        let textOrigin = CGPoint(x: textView.textContainerInset.left - textView.contentOffset.x,
                                 y: textView.textContainerInset.top - textView.contentOffset.y)
        let segments = layoutSegments(in: text,
                                      size: textView.textContainer.size,
                                      font: textView.font,
                                      alignment: textView.textAlignment,
                                      numberOfLines: textView.textContainer.maximumNumberOfLines,
                                      lineBreakMode: textView.textContainer.lineBreakMode,
                                      lineFragmentPadding: textView.textContainer.lineFragmentPadding)
        paint(segments, origin: textOrigin, clipping: textView.bounds, traitCollection: textView.traitCollection)
    }

    // Shared geometry for painting and action hit testing.
    // A painted background with .action is tappable, and hitTestInsets can
    // extend the target beyond the painted rect without increasing text layout.
    static func actionIndex(at point: CGPoint, on label: UILabel) -> Int? {
        guard label is PTRichTextStyledLabel || label is PTRichTextFlowLabel,
              let text = label.attributedText, hasRoundedBackground(in: text) else { return nil }
        let rect = label.textRect(forBounds: label.bounds,
                                  limitedToNumberOfLines: label.numberOfLines)
        return actionIndex(at: point,
                           in: text,
                           size: rect.size,
                           origin: rect.origin,
                           font: label.font,
                           alignment: label.textAlignment,
                           numberOfLines: label.numberOfLines,
                           lineBreakMode: label.lineBreakMode)
    }

    static func actionIndex(at point: CGPoint, on textView: UITextView) -> Int? {
        guard textView is PTRichTextStyledTextView,
              let text = textView.attributedText, hasRoundedBackground(in: text) else { return nil }
        return actionIndex(at: point,
                           in: text,
                           size: textView.textContainer.size,
                           origin: CGPoint(x: textView.textContainerInset.left - textView.contentOffset.x,
                                           y: textView.textContainerInset.top - textView.contentOffset.y),
                           font: textView.font,
                           alignment: textView.textAlignment,
                           numberOfLines: textView.textContainer.maximumNumberOfLines,
                           lineBreakMode: textView.textContainer.lineBreakMode,
                           lineFragmentPadding: textView.textContainer.lineFragmentPadding)
    }

    private static func actionIndex(at point: CGPoint,
                                    in text: NSAttributedString,
                                    size: CGSize,
                                    origin: CGPoint,
                                    font: UIFont?,
                                    alignment: NSTextAlignment,
                                    numberOfLines: Int,
                                    lineBreakMode: NSLineBreakMode,
                                    lineFragmentPadding: CGFloat = 0) -> Int? {
        guard let layout = makeLayout(for: text,
                                      size: size,
                                      font: font,
                                      alignment: alignment,
                                      numberOfLines: numberOfLines,
                                      lineBreakMode: lineBreakMode,
                                      lineFragmentPadding: lineFragmentPadding) else { return nil }
        let local = CGPoint(x: point.x - origin.x, y: point.y - origin.y)

        // Glyphs (including neighboring plain text, links and attachments)
        // win before any enlarged rounded-background target.
        var fraction: CGFloat = 0
        let index = layout.manager.characterIndex(for: local,
                                                   in: layout.container,
                                                   fractionOfDistanceBetweenInsertionPoints: &fraction)
        if index < text.length {
            let glyphs = layout.manager.glyphRange(forCharacterRange: NSRange(location: index, length: 1),
                                                    actualCharacterRange: nil)
            let visibleGlyphs = NSIntersectionRange(glyphs, layout.visible)
            if visibleGlyphs.length > 0 {
                let rect = layout.manager.boundingRect(forGlyphRange: visibleGlyphs,
                                                        in: layout.container)
                if rect.contains(local) {
                    // Spaces are often intentionally covered by painted padding.
                    // Non-whitespace text, links and attachments must retain priority.
                    let character = (text.string as NSString).substring(with: NSRange(location: index, length: 1))
                    if !character.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return nil
                    }
                }
            }
        }

        let segments = segments(in: text, layout: layout)
        var candidates: [(index: Int, distance: CGFloat)] = []
        for segment in segments where segment.characterRange.length > 0 {
            // A decoration can span multiple Action IDs (or nonaction text).
            // Split hit regions by Action runs without altering painted layout.
            text.enumerateAttribute(PTRichText.actionAttributeKey,
                                    in: segment.characterRange,
                                    options: []) { action, characters, _ in
                guard action as? String != nil else { return }
                let glyphs = layout.manager.glyphRange(forCharacterRange: characters,
                                                       actualCharacterRange: nil)
                let visible = NSIntersectionRange(glyphs, layout.visible)
                guard visible.length > 0 else { return }
                let glyphRect = layout.manager.boundingRect(forGlyphRange: visible,
                                                             in: layout.container)
                guard glyphRect.width > 0, glyphRect.height > 0 else { return }
                let style = segment.style
                let painted = CGRect(x: glyphRect.minX - CGFloat(style.left),
                                     y: glyphRect.minY - CGFloat(style.top),
                                     width: glyphRect.width + CGFloat(style.left + style.right),
                                     height: glyphRect.height + CGFloat(style.top + style.bottom))
                let expanded = painted.inset(by: UIEdgeInsets(
                    top: -style.hitInsets.top,
                    left: -style.hitInsets.left,
                    bottom: -style.hitInsets.bottom,
                    right: -style.hitInsets.right))
                guard expanded.contains(local) else { return }
                // Nearby overlapping targets use visual proximity, never
                // attribute enumeration order. The source action range survives.
                let dx = local.x - painted.midX
                let dy = local.y - painted.midY
                candidates.append((characters.location, dx * dx + dy * dy))
            }
        }
        return candidates.min(by: { $0.distance < $1.distance })?.index
    }

    private struct TextLayout {
        let storage: NSTextStorage
        let manager: NSLayoutManager
        let container: NSTextContainer
        let visible: NSRange
    }

    // Shared line-fragment geometry; ranges split at wraps and exclude truncated glyphs.
    static func layoutSegments(in text: NSAttributedString,
                               size: CGSize,
                               font: UIFont?,
                               alignment: NSTextAlignment,
                               numberOfLines: Int,
                               lineBreakMode: NSLineBreakMode,
                               lineFragmentPadding: CGFloat = 0) -> [PTTextRoundedBackgroundSegment] {
        guard let layout = makeLayout(for: text,
                                      size: size,
                                      font: font,
                                      alignment: alignment,
                                      numberOfLines: numberOfLines,
                                      lineBreakMode: lineBreakMode,
                                      lineFragmentPadding: lineFragmentPadding) else { return [] }
        return segments(in: text, layout: layout)
    }

    private static func makeLayout(for text: NSAttributedString,
                                   size: CGSize,
                                   font: UIFont?,
                                   alignment: NSTextAlignment,
                                   numberOfLines: Int,
                                   lineBreakMode: NSLineBreakMode,
                                   lineFragmentPadding: CGFloat) -> TextLayout? {
        guard text.length > 0, size.width > 0, size.height > 0 else { return nil }
        let storage = NSTextStorage(attributedString: text)
        let full = NSRange(location: 0, length: storage.length)
        // Collect missing runs first: mutating NSTextStorage during its enumeration is unsafe.
        var missingFonts: [NSRange] = []
        var missingParagraphs: [NSRange] = []
        text.enumerateAttribute(.font, in: full, options: []) { value, range, _ in
            if value == nil { missingFonts.append(range) }
        }
        text.enumerateAttribute(.paragraphStyle, in: full, options: []) { value, range, _ in
            if value == nil { missingParagraphs.append(range) }
        }
        for range in missingFonts {
            storage.addAttribute(.font, value: font ?? UIFont.systemFont(ofSize: 17), range: range)
        }
        for range in missingParagraphs {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = alignment
            paragraph.lineBreakMode = lineBreakMode
            storage.addAttribute(.paragraphStyle, value: paragraph, range: range)
        }

        let manager = NSLayoutManager()
        let container = NSTextContainer(size: size)
        container.lineFragmentPadding = lineFragmentPadding
        container.maximumNumberOfLines = max(0, numberOfLines)
        container.lineBreakMode = lineBreakMode
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)
        let visible = manager.glyphRange(for: container)
        guard visible.length > 0 else { return nil }
        return TextLayout(storage: storage, manager: manager, container: container, visible: visible)
    }

    private static func segments(in text: NSAttributedString,
                                 layout: TextLayout) -> [PTTextRoundedBackgroundSegment] {
        let storage = layout.storage
        let manager = layout.manager
        let container = layout.container
        let visible = layout.visible
        let full = NSRange(location: 0, length: storage.length)
        var segments: [PTTextRoundedBackgroundSegment] = []
        storage.enumerateAttribute(PTRichText.roundedBackgroundAttributeKey, in: full, options: []) { value, charRange, _ in
            guard let style = PTTextRoundedBackgroundSpec.decode(value) else { return }
            let glyphs = manager.glyphRange(forCharacterRange: charRange,
                                            actualCharacterRange: nil)
            let candidate = NSIntersectionRange(glyphs, visible)
            guard candidate.length > 0 else { return }

            manager.enumerateLineFragments(forGlyphRange: candidate) { _, _, _, lineGlyphs, _ in
                let onLine = NSIntersectionRange(candidate, lineGlyphs)
                guard onLine.length > 0 else { return }
                let truncated = manager.truncatedGlyphRange(inLineFragmentForGlyphAt: lineGlyphs.location)
                let pieces: [NSRange]
                if truncated.location != NSNotFound, truncated.length > 0 {
                    pieces = self.subtract(truncated, from: onLine)
                } else {
                    pieces = [onLine]
                }
                for piece in pieces where piece.length > 0 {
                    let glyphRect = manager.boundingRect(forGlyphRange: piece, in: container)
                    guard !glyphRect.isNull, glyphRect.width > 0, glyphRect.height > 0 else { continue }
                    let padded = CGRect(x: glyphRect.minX - CGFloat(style.left),
                                        y: glyphRect.minY - CGFloat(style.top),
                                        width: glyphRect.width + CGFloat(style.left + style.right),
                                        height: glyphRect.height + CGFloat(style.top + style.bottom))
                    let characters = manager.characterRange(forGlyphRange: piece,
                                                             actualGlyphRange: nil)
                    let styledCharacters = NSIntersectionRange(characters, charRange)
                    guard styledCharacters.length > 0 else { continue }
                    segments.append(PTTextRoundedBackgroundSegment(rect: padded,
                                                                    characterRange: styledCharacters,
                                                                    style: style))
                }
            }
        }
        return segments
    }

    private static func subtract(_ hidden: NSRange, from visible: NSRange) -> [NSRange] {
        let overlap = NSIntersectionRange(hidden, visible)
        guard overlap.length > 0 else { return [visible] }
        var pieces: [NSRange] = []
        if visible.location < overlap.location {
            pieces.append(NSRange(location: visible.location,
                                  length: overlap.location - visible.location))
        }
        if NSMaxRange(overlap) < NSMaxRange(visible) {
            pieces.append(NSRange(location: NSMaxRange(overlap),
                                  length: NSMaxRange(visible) - NSMaxRange(overlap)))
        }
        return pieces
    }

    // A background can protrude beyond a tightly constrained UILabel (for
    // instance its intrinsic height equals the text height plus no padding).
    // Clipping the original rounded path produces straight edges when its
    // rounded corners fall entirely outside the host bounds. Construct the
    // visible shape first, then round that shape so corners remain visible.
    // This is a best-effort display fallback: it cannot manufacture layout
    // space beyond UIView.bounds.
    static func paintedGeometry(for rawRect: CGRect,
                                clipping: CGRect,
                                style: PTTextRoundedBackgroundSpec) -> (rect: CGRect, radius: CGFloat)? {
        guard rawRect.width > 0, rawRect.height > 0,
              clipping.width > 0, clipping.height > 0,
              !rawRect.isNull, !clipping.isNull else { return nil }
        let visible = rawRect.intersection(clipping)
        guard !visible.isNull, visible.width > 0, visible.height > 0 else { return nil }
        let maxRadius = min(visible.width, visible.height) / 2
        let radius: CGFloat
        if style.cornerMode == .capsule {
            radius = maxRadius
        } else {
            radius = min(CGFloat(style.radius), maxRadius)
        }
        return (visible, radius)
    }

    private static func paint(_ segments: [PTTextRoundedBackgroundSegment],
                              origin: CGPoint,
                              clipping: CGRect,
                              traitCollection: UITraitCollection) {
        guard !segments.isEmpty, let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.clip(to: clipping)
        for segment in segments {
            let style = segment.style
            let original = segment.rect.offsetBy(dx: origin.x, dy: origin.y)
            guard let geometry = paintedGeometry(for: original,
                                                  clipping: clipping,
                                                  style: style) else { continue }
            let rect = geometry.rect
            let radius = geometry.radius
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            style.fill.resolve(for: traitCollection).setFill()
            path.fill()
            if let stroke = style.stroke, style.strokeWidth > 0 {
                let width = min(CGFloat(style.strokeWidth), min(rect.width, rect.height))
                let strokeRect = rect.insetBy(dx: width / 2, dy: width / 2)
                let strokePath = UIBezierPath(roundedRect: strokeRect,
                                               cornerRadius: max(0, radius - width / 2))
                stroke.resolve(for: traitCollection).setStroke()
                strokePath.lineWidth = width
                strokePath.stroke()
            }
        }
        context.restoreGState()
    }
}

// Opt-in because UIKit UILabel has no public callback for drawing behind text glyphs.
@MainActor
public final class PTRichTextStyledLabel: UILabel {
    public override func drawText(in rect: CGRect) {
        PTRichTextRoundedBackgroundRenderer.draw(on: self, in: rect)
        super.drawText(in: rect)
    }
}

@MainActor
public final class PTRichTextStyledTextView: UITextView {
    public override func draw(_ rect: CGRect) {
        PTRichTextRoundedBackgroundRenderer.draw(on: self)
        super.draw(rect)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
}
