import UIKit

/// Creates the windows that toasts are presented in.
@MainActor
protocol ToastWindowSource: AnyObject {
    /// Called whenever `makeWindow()` may have started returning a window.
    var availabilityDidChange: (() -> Void)? { get set }

    /// A new window for presenting a toast, or nil if a toast can't be shown right now.
    func makeWindow() -> ToastWindow?

    /// Called with the window scene of the view that presents the toasts.
    func hostSceneDidChange(_ scene: UIWindowScene?)
}

/// Creates toast windows in the scene of the presenting view, once that scene is active.
@MainActor
final class SceneToastWindowSource: ToastWindowSource {
    var availabilityDidChange: (() -> Void)?

    private weak var scene: UIWindowScene?
    nonisolated(unsafe) private var activationObserver: NSObjectProtocol?

    deinit {
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
        }
    }

    func makeWindow() -> ToastWindow? {
        guard let scene, scene.activationState == .foregroundActive else { return nil }

        let window = ToastWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        return window
    }

    func hostSceneDidChange(_ scene: UIWindowScene?) {
        guard scene !== self.scene else { return }
        self.scene = scene

        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
            self.activationObserver = nil
        }

        if let scene {
            activationObserver = NotificationCenter.default.addObserver(
                forName: UIScene.didActivateNotification,
                object: scene,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.availabilityDidChange?()
                }
            }
        }

        // Scene changes are reported during a view update, so present afterwards.
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                self?.availabilityDidChange?()
            }
        }
    }
}
