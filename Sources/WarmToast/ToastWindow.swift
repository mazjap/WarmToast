import UIKit

final class ToastWindow: UIWindow {
    /// The toast's frame in window coordinates, or nil when no toast is on screen.
    var toastFrame: CGRect?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // SwiftUI can draw content directly in the hosting view, so the hit view alone can't tell
        // the toast apart from the transparent space around it. Touches outside the toast's frame
        // pass through to the windows below.
        guard let toastFrame, toastFrame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}
