import Foundation

/// Counts down a toast's time on screen. The countdown can be paused while the user interacts with the toast.
@MainActor
final class DismissCountdown {
    private let duration: PresentedDuration
    private var remaining: TimeInterval = 0
    private var resumedAt: Date?
    private var task: Task<Void, Never>?
    private var onFinish: (() -> Void)?

    var isRunning: Bool {
        task != nil
    }

    init(duration: PresentedDuration) {
        self.duration = duration
    }

    deinit {
        task?.cancel()
    }

    /// Starts counting down from the full duration. Does nothing for `PresentedDuration.indefinitely`.
    func start(onFinish: @escaping () -> Void) {
        guard case let .seconds(seconds) = duration else { return }

        cancel()
        self.onFinish = onFinish
        remaining = seconds
        resume()
    }

    /// Stops the countdown and keeps the time that is left.
    func pause() {
        guard let task, let resumedAt else { return }

        task.cancel()
        self.task = nil
        self.resumedAt = nil
        remaining -= Date().timeIntervalSince(resumedAt)
    }

    /// Continues a paused countdown with the time that was left.
    func resume() {
        guard task == nil, onFinish != nil else { return }

        resumedAt = Date()
        let delay = max(0, remaining)
        task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self else { return }

            let onFinish = self.onFinish
            self.cancel()
            onFinish?()
        }
    }

    /// Stops the countdown for good.
    func cancel() {
        task?.cancel()
        task = nil
        resumedAt = nil
        onFinish = nil
    }
}
