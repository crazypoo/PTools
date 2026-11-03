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

// English: Primitive-only value survives Foundation.AttributedString copying and Swift 6 isolation.
public struct PTTextRoundedBackgroundSpec: Codable, Hashable, Sendable {
    let fill: PTTextBackgroundColorPair
    let stroke: PTTextBackgroundColorPair?
    let radius: Double
    let top: Double
    let left: Double
    let bottom: Double
    let right: Double
    let strokeWidth: Double

    init(color: UIColor,
         cornerRadius: CGFloat,
         insets: UIEdgeInsets,
         borderColor: UIColor?,
         borderWidth: CGFloat) {
        fill = PTTextBackgroundColorPair(color)
        stroke = borderColor.map(PTTextBackgroundColorPair.init)
        radius = Double(max(0, cornerRadius.isFinite ? cornerRadius : 0))
        top = Double(max(0, insets.top.isFinite ? insets.top : 0))
        left = Double(max(0, insets.left.isFinite ? insets.left : 0))
        bottom = Double(max(0, insets.bottom.isFinite ? insets.bottom : 0))
        right = Double(max(0, insets.right.isFinite ? insets.right : 0))
        strokeWidth = Double(max(0, borderWidth.isFinite ? borderWidth : 0))
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

    // UILabel and UITextView otherwise paint NSAttributedString.backgroundColor as a square.
    static func textForDecoratedHost(_ text: NSAttributedString) -> NSAttributedString {
        guard text.length > 0 else { return text }
        var ranges: [NSRange] = []
        text.enumerateAttribute(PTRichText.roundedBackgroundAttributeKey,
                                in: NSRange(location: 0, length: text.length),
                                options: []) { value, range, _ in
            if PTTextRoundedBackgroundSpec.decode(value) != nil {
                ranges.append(range)
            }
        }
        guard !ranges.isEmpty else { return text }
        let result = NSMutableAttributedString(attributedString: text)
        for range in ranges {
            result.removeAttribute(.backgroundColor, range: range)
        }
        return result
    }

    static func draw(on label: UILabel, in rect: CGRect) {
        guard let text = label.attributedText, hasRoundedBackground(in: text) else { return }
        let textRect = label.textRect(forBounds: rect,
                                      limitedToNumberOfLines: label.numberOfLines)
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
        let textOrigin = CGPoint(x: textView.textContainerInset.left,
                                 y: textView.textContainerInset.top)
        let segments = layoutSegments(in: text,
                                      size: textView.textContainer.size,
                                      font: textView.font,
                                      alignment: textView.textAlignment,
                                      numberOfLines: 0,
                                      lineBreakMode: .byWordWrapping)
        paint(segments, origin: textOrigin, clipping: textView.bounds, traitCollection: textView.traitCollection)
    }

    // Shared line-fragment geometry; ranges split at wraps and excludes truncated glyphs.
    static func layoutSegments(in text: NSAttributedString,
                               size: CGSize,
                               font: UIFont?,
                               alignment: NSTextAlignment,
                               numberOfLines: Int,
                               lineBreakMode: NSLineBreakMode) -> [PTTextRoundedBackgroundSegment] {
        guard text.length > 0, size.width > 0, size.height > 0 else { return [] }
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
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = max(0, numberOfLines)
        container.lineBreakMode = lineBreakMode
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)
        let visible = manager.glyphRange(for: container)
        guard visible.length > 0 else { return [] }

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
                    segments.append(PTTextRoundedBackgroundSegment(rect: padded, style: style))
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

    private static func paint(_ segments: [PTTextRoundedBackgroundSegment],
                              origin: CGPoint,
                              clipping: CGRect,
                              traitCollection: UITraitCollection) {
        guard !segments.isEmpty, let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.clip(to: clipping)
        for segment in segments {
            let style = segment.style
            let rect = segment.rect.offsetBy(dx: origin.x, dy: origin.y)
            let radius = min(CGFloat(style.radius), min(rect.width / 2, rect.height / 2))
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
