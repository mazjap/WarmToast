import SwiftUI
import UIKit

final class ToastWindow: UIWindow {
    /// A view laid out behind the toast that marks where the toast is.
    weak var toastHitArea: UIView?

    /// The toast's frame in window coordinates, or nil when no toast is on screen.
    var toastFrame: CGRect? {
        guard let toastHitArea, toastHitArea.window === self else { return nil }
        return toastHitArea.convert(toastHitArea.bounds, to: self)
    }

    /// A toast window never takes key status from the app's window. A window shown while the scene has
    /// no key window, such as during launch, would otherwise become key.
    override var canBecomeKey: Bool {
        false
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // SwiftUI can draw content directly in the hosting view, so the hit view alone can't tell
        // the toast apart from the transparent space around it. Touches outside the toast's frame
        // pass through to the windows below.
        guard let toastFrame, toastFrame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// Marks the toast's area for `ToastWindow` hit testing.
///
/// This is a UIKit view rather than a SwiftUI frame measurement, because its frame is read when a
/// touch lands. A measurement reported from SwiftUI can be stale, for example when it was taken at
/// the start of the insertion transition.
struct ToastHitArea: UIViewRepresentable {
    func makeUIView(context: Context) -> ToastHitAreaView {
        let view = ToastHitAreaView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: ToastHitAreaView, context: Context) {}
}

final class ToastHitAreaView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        (window as? ToastWindow)?.toastHitArea = self
    }
}
