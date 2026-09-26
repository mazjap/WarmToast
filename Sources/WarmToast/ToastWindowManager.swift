import SwiftUI
import UIKit

@MainActor
final class ToastWindowManager {
    private let windowSource: ToastWindowSource
    private var pendingToast: PendingToast?
    private(set) var window: ToastWindow?
    private(set) var presentationID: UUID?
    private var dismissSignal: ToastDismissSignal?
    private var onDismiss: (() -> Void)?

    /// A toast waiting for a window, for example while its scene is in the background.
    private struct PendingToast {
        let id = UUID()
        let makeRootViewController: (UUID, ToastDismissSignal) -> UIViewController
        let onDismiss: () -> Void
    }

    /// Makes the window source for managers created without one. Tests replace it to present toasts
    /// without a real window scene.
    static var makeDefaultWindowSource: () -> ToastWindowSource = { SceneToastWindowSource() }

    init(windowSource: ToastWindowSource? = nil) {
        let windowSource = windowSource ?? Self.makeDefaultWindowSource()
        self.windowSource = windowSource
        windowSource.availabilityDidChange = { [weak self] in
            self?.presentPendingToastIfPossible()
        }
    }

    var isPending: Bool {
        pendingToast != nil
    }

    /// Shows a toast in a new window, replacing any toast this manager is showing.
    /// - Parameters:
    ///   - onDismiss: Called once the toast has left the screen, or when a toast that never got a window is hidden.
    ///   - makeHost: Builds the window's root view. The view must call `didDisappear` when the toast leaves the screen.
    func show<Host: View>(
        onDismiss: @escaping () -> Void,
        makeHost: @escaping (_ dismissSignal: ToastDismissSignal, _ didDisappear: @escaping () -> Void) -> Host
    ) {
        tearDown()

        pendingToast = PendingToast(
            makeRootViewController: { [weak self] id, signal in
                let hostView = makeHost(signal) {
                    self?.toastDidDisappear(presentationID: id)
                }

                let hostingController = UIHostingController(rootView: hostView)
                hostingController.view.backgroundColor = .clear
                return hostingController
            },
            onDismiss: onDismiss
        )

        presentPendingToastIfPossible()
    }

    func hide() {
        if let pendingToast {
            // The toast was never shown, so it's done as soon as it's hidden.
            tearDown()
            pendingToast.onDismiss()
        } else {
            dismissSignal?.shouldDismiss = true
        }
    }

    func hostSceneDidChange(_ scene: UIWindowScene?) {
        windowSource.hostSceneDidChange(scene)
    }

    func cleanup() {
        tearDown()
    }

    private func presentPendingToastIfPossible() {
        guard let pendingToast, let toastWindow = windowSource.makeWindow() else { return }

        let signal = ToastDismissSignal()
        toastWindow.rootViewController = pendingToast.makeRootViewController(pendingToast.id, signal)
        toastWindow.isHidden = false

        self.pendingToast = nil
        self.window = toastWindow
        self.presentationID = pendingToast.id
        self.dismissSignal = signal
        self.onDismiss = pendingToast.onDismiss
    }

    /// Called when a toast's content leaves the screen.
    func toastDidDisappear(presentationID id: UUID) {
        // A replaced window can report its disappearance after the next toast is already up.
        guard id == presentationID else { return }
        
        let onDismiss = onDismiss
        tearDown()
        onDismiss?()
    }

    private func tearDown() {
        window?.isHidden = true
        window = nil
        presentationID = nil
        dismissSignal = nil
        onDismiss = nil
        pendingToast = nil
    }
}
