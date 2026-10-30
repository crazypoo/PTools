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
}
