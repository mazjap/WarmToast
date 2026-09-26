import Testing
@testable import WarmToast

@MainActor
@Suite struct DismissCountdownTests {
    @Test func finishesAfterItsDuration() async {
        let countdown = DismissCountdown(duration: .seconds(0.05))
        let finishes = CallCounter()
        
        countdown.start(onFinish: finishes.increment)
        #expect(countdown.isRunning)
        
        #expect(await waitUntil { finishes.count == 1 })
        #expect(!countdown.isRunning)
    }
    
    @Test func indefiniteDurationNeverStarts() {
        let countdown = DismissCountdown(duration: .indefinitely)
        
        countdown.start {}
        
        #expect(!countdown.isRunning)
    }
    
    @Test func pausingHoldsTheToastOnScreen() async throws {
        let countdown = DismissCountdown(duration: .seconds(0.1))
        let finishes = CallCounter()
        
        countdown.start(onFinish: finishes.increment)
        countdown.pause()
        try await Task.sleep(for: .milliseconds(300))
        
        #expect(finishes.count == 0)
        #expect(!countdown.isRunning)
        
        countdown.resume()
        
        #expect(await waitUntil { finishes.count == 1 })
    }
    
    @Test func resumingUsesTheTimeThatWasLeft() async throws {
        let countdown = DismissCountdown(duration: .seconds(0.4))
        let finishes = CallCounter()
        
        countdown.start(onFinish: finishes.increment)
        try await Task.sleep(for: .milliseconds(300))
        countdown.pause()
        countdown.resume()
        
        // About 0.1 seconds were left, well short of a fresh 0.4.
        try await Task.sleep(for: .milliseconds(250))
        #expect(finishes.count == 1)
    }
    
    @Test func cancellingStopsTheCountdownForGood() async throws {
        let countdown = DismissCountdown(duration: .seconds(0.05))
        let finishes = CallCounter()
        
        countdown.start(onFinish: finishes.increment)
        countdown.cancel()
        countdown.resume()
        try await Task.sleep(for: .milliseconds(200))
        
        #expect(finishes.count == 0)
    }
}
