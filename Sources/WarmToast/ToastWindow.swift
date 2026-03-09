import UIKit

final class ToastWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        // Pass touches through to the underlying window when they land on the
        // transparent background rather than on the toast content itself.
        return hitView == rootViewController?.view ? nil : hitView
    }
}
