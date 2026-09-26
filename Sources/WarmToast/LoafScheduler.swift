import Foundation

/// Decides when the next toast in a loaf may start, so only one toast is shown at a time.
@MainActor
final class LoafScheduler {
    private(set) var isToasting = false
    private(set) var isPausingBetweenToasts = false
    private var pauseTask: Task<Void, Never>?

    deinit {
        pauseTask?.cancel()
    }

    /// Starts the next toast unless one is showing or the pause after the last one hasn't ended.
    /// - Parameter startNext: Starts the next toast and returns whether there was one to start.
    func advance(startNext: () -> Bool) {
        guard !isToasting, !isPausingBetweenToasts else { return }
        isToasting = startNext()
    }

    /// Marks the current toast as finished and advances once `pause` has passed.
    func toastDidFinish(pause: TimeInterval, then startNext: @escaping @MainActor () -> Bool) {
        isToasting = false
        isPausingBetweenToasts = true
        pauseTask?.cancel()
        pauseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, pause)))
            guard !Task.isCancelled, let self else { return }

            self.isPausingBetweenToasts = false
            self.advance(startNext: startNext)
        }
    }
}
