import SwiftUI
import UIKit
@testable import WarmToast

/// A window source whose availability tests control directly, standing in for a real scene.
@MainActor
final class FakeToastWindowSource: ToastWindowSource {
    var availabilityDidChange: (() -> Void)?
    var isAvailable: Bool

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    /// Every window this source has made, oldest first.
    private(set) var madeWindows: [ToastWindow] = []
    
    func makeWindow() -> ToastWindow? {
        guard isAvailable else { return nil }
        let window = ToastWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        madeWindows.append(window)
        return window
    }

    func hostSceneDidChange(_ scene: UIWindowScene?) {}

    func becomeAvailable() {
        isAvailable = true
        availabilityDidChange?()
    }
}

/// Counts calls to a callback.
@MainActor
final class CallCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

extension ToastWindowManager {
    /// Shows a text toast through the real toast host, from a bread box of its own.
    func show(_ message: String, duration: PresentedDuration = .indefinitely, onDismiss: @escaping () -> Void = {}) {
        let box = BreadBox<String>()
        box.toast(message)
        let order = box.current!
        
        show(onDismiss: onDismiss) { dismissSignal, didDisappear in
            ToastWindowHost(
                box: box,
                order: order,
                options: { _ in .toasterStrudel(type: .info, duration: duration) },
                toast: { Text($0) },
                dismissSignal: dismissSignal,
                onDisappear: didDisappear
            )
        }
    }
}

/// Polls `condition` on the main actor until it holds or the timeout passes.
@MainActor
func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline { return false }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return true
}

/// Hosts a view in a window of its own, with toasters presenting through `source`.
@MainActor
final class ToasterHarness {
    let source = FakeToastWindowSource()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    
    init(@ViewBuilder content: () -> some View) {
        let source = source
        ToastWindowManager.makeDefaultWindowSource = { source }
        window.rootViewController = UIHostingController(rootView: content())
        window.isHidden = false
    }
    
    /// The newest toast window, if it's on screen.
    var visibleToastWindow: ToastWindow? {
        source.madeWindows.last.flatMap { $0.isHidden ? nil : $0 }
    }
    
    func tearDown() {
        window.isHidden = true
        window.rootViewController = nil
        ToastWindowManager.makeDefaultWindowSource = { SceneToastWindowSource() }
    }
}
