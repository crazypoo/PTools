// UIKit drawing is a reusable leaf; Metrics collectors and the recording
// session remain owned by the existing Debug module.
import UIKit

@MainActor
public enum PTDebugMetricsTrackRenderer {
    /// Matches the 5.x timeline geometry and accessibility font choices.
    /// Pass titles in visible-track order; this renderer never samples data.
    public static func drawTrackGrid(titles: [String], width: CGFloat,
                                     context: CGContext?) {
        context?.setLineWidth(1)
        // Resolve Dynamic Type font and foreground once per paint pass,
        // not once per visible track. Do not cache across trait changes.
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .caption1),
            .foregroundColor: UIColor.secondaryLabel
        ]
        for (index, title) in titles.enumerated() {
            let y = CGFloat(index * 48) + 24
            UIColor.separator.setStroke()
            context?.move(to: CGPoint(x: 0, y: y + 16))
            context?.addLine(to: CGPoint(x: width, y: y + 16))
            context?.strokePath()
            title.draw(at: CGPoint(x: 8, y: y - 18), withAttributes: attributes)
        }
    }
    /// PR44: same-package/internal drawing adapters. These are NOT public
    /// APIs; the existing public grid renderer remains source-compatible.
    /// CocoaPods builds the Debug files in one module, while SwiftPM uses
    /// package visibility across the isolated Debug and Metrics UI targets.
#if SWIFT_PACKAGE
    package static func drawSample(x: CGFloat, trackY: CGFloat, context: CGContext?) {
        paintSample(x: x, trackY: trackY, context: context)
    }

    package static func drawEvent(x: CGFloat, trackY: CGFloat, context: CGContext?) {
        paintEvent(x: x, trackY: trackY, context: context)
    }

    package static func drawSelection(startX: CGFloat, endX: CGFloat,
                                      height: CGFloat, context: CGContext?) {
        paintSelection(startX: startX, endX: endX, height: height, context: context)
    }
#else
    static func drawSample(x: CGFloat, trackY: CGFloat, context: CGContext?) {
        paintSample(x: x, trackY: trackY, context: context)
    }

    static func drawEvent(x: CGFloat, trackY: CGFloat, context: CGContext?) {
        paintEvent(x: x, trackY: trackY, context: context)
    }

    static func drawSelection(startX: CGFloat, endX: CGFloat,
                              height: CGFloat, context: CGContext?) {
        paintSelection(startX: startX, endX: endX, height: height, context: context)
    }
#endif

    private static func paintSample(x: CGFloat, trackY: CGFloat, context: CGContext?) {
        UIColor.systemBlue.setFill()
        context?.fill(CGRect(x: x, y: trackY + 4, width: 2, height: 10))
    }

    private static func paintEvent(x: CGFloat, trackY: CGFloat, context: CGContext?) {
        UIColor.systemOrange.setFill()
        context?.fillEllipse(in: CGRect(x: x - 3, y: trackY - 2, width: 6, height: 6))
    }

    private static func paintSelection(startX: CGFloat, endX: CGFloat,
                                       height: CGFloat, context: CGContext?) {
        UIColor.systemBlue.withAlphaComponent(0.12).setFill()
        context?.fill(CGRect(x: startX, y: 0,
                             width: max(0, endX - startX), height: height))
    }

}
