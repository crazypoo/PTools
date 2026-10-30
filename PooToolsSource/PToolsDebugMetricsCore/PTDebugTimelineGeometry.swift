import Foundation

/// Platform-neutral timeline layout used by the iOS Instruments renderer.
/// This module never owns a display link, UIView, timer or sampling session.
public struct PTDebugTimelineGeometry: Sendable, Equatable {
    public let contentWidth: Double
    public let contentHeight: Double

    public init(viewportWidth: Double,
                duration: TimeInterval,
                zoom: Double,
                visibleTrackCount: Int) {
        let safeWidth = viewportWidth.isFinite ? max(0, viewportWidth) : 0
        let safeDuration = duration.isFinite ? max(0, duration) : 0
        let safeZoom = zoom.isFinite ? min(8, max(0.5, zoom)) : 1
        contentWidth = max(safeWidth, safeDuration * 120 * safeZoom + 40)
        contentHeight = Double(max(1, visibleTrackCount)) * 48
    }

    /// Position of a sample/event within an existing timeline canvas.
    /// Matches the 20pt origin and drawable width used by the 5.x UI.
    public static func xPosition(elapsed: TimeInterval,
                                 contentWidth: Double,
                                 duration: TimeInterval) -> Double {
        guard elapsed.isFinite, contentWidth.isFinite, duration.isFinite else { return 20 }
        return 20 + elapsed * max(1, contentWidth - 40) / max(0.001, duration)
    }
}
