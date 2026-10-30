import UIKit

/// UIKit presentation leaf for the authorized Debug Inspector.
/// The hierarchy snapshot, privacy policy, and Studio transport remain owned
/// by their separate data-only targets. There is no swizzle or global window.
@MainActor
public enum PTDebugInspectorHighlight {
    /// Adds a short-lived overlay to the target's existing UIWindow.
    /// Returning before attachment is intentional: never create a new window.
    public static func show(_ view: UIView) {
        guard let window = view.window else { return }
        let frame = view.convert(view.bounds, to: window)
        let layer = CAShapeLayer()
        layer.frame = frame
        layer.borderColor = UIColor.systemOrange.cgColor
        layer.borderWidth = 3
        layer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1).cgColor
        window.layer.addSublayer(layer)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            layer.removeFromSuperlayer()
        }
    }
}
