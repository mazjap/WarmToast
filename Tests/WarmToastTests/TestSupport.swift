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

    func makeWindow() -> ToastWindow? {
        guard isAvailable else { return nil }
        return ToastWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
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
    func show(_ message: String, onDismiss: @escaping () -> Void = {}) {
        show(
            bread: message,
            options: .toasterStrudel(type: .info, duration: .indefinitely),
            toast: { Text($0) },
            onDismiss: onDismiss
        )
    }
}

/// Polls `condition` on the main actor until it holds or the timeout passes.
@MainActor
func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline { return false }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
    return true
}
