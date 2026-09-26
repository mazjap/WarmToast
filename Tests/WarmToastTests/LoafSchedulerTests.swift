import Testing
@testable import WarmToast

@MainActor
@Suite struct LoafSchedulerTests {
    /// A loaf of messages and the ones that have been toasted so far.
    @MainActor
    final class Loaf {
        var queue: [String]
        private(set) var toasted: [String] = []
        
        init(_ queue: [String]) {
            self.queue = queue
        }
        
        func makeMoreToast() -> Bool {
            guard !queue.isEmpty else { return false }
            toasted.append(queue.removeFirst())
            return true
        }
    }
    
    @Test func startsTheFirstToastRightAway() {
        let scheduler = LoafScheduler()
        let loaf = Loaf(["A", "B"])
        
        scheduler.advance(startNext: loaf.makeMoreToast)
        
        #expect(loaf.toasted == ["A"])
        #expect(scheduler.isToasting)
    }
    
    @Test func doesNotStartAnotherToastWhileOneIsShowing() {
        let scheduler = LoafScheduler()
        let loaf = Loaf(["A", "B"])
        
        scheduler.advance(startNext: loaf.makeMoreToast)
        scheduler.advance(startNext: loaf.makeMoreToast)
        
        #expect(loaf.toasted == ["A"])
        #expect(loaf.queue == ["B"])
    }
    
    @Test func loafChangesDuringThePauseDoNotSkipAToast() async {
        // Regression: a loaf change during the pause started a toast right away, and the end of the
        // pause then removed the next one from the loaf while that toast was still showing.
        let scheduler = LoafScheduler()
        let loaf = Loaf(["A"])
        
        scheduler.advance(startNext: loaf.makeMoreToast)
        scheduler.toastDidFinish(pause: 0.1, then: loaf.makeMoreToast)
        
        loaf.queue += ["B", "C"]
        scheduler.advance(startNext: loaf.makeMoreToast)
        #expect(loaf.toasted == ["A"])
        
        #expect(await waitUntil { loaf.toasted.count == 2 })
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        #expect(loaf.toasted == ["A", "B"])
        #expect(loaf.queue == ["C"])
    }
    
    @Test func startsTheNextToastAfterThePause() async {
        let scheduler = LoafScheduler()
        let loaf = Loaf(["A", "B"])
        
        scheduler.advance(startNext: loaf.makeMoreToast)
        scheduler.toastDidFinish(pause: 0.05, then: loaf.makeMoreToast)
        
        #expect(await waitUntil { loaf.toasted == ["A", "B"] })
        #expect(scheduler.isToasting)
        #expect(!scheduler.isPausingBetweenToasts)
    }
    
    @Test func anEmptyLoafLeavesTheSchedulerIdle() async {
        let scheduler = LoafScheduler()
        let loaf = Loaf(["A"])
        
        scheduler.advance(startNext: loaf.makeMoreToast)
        scheduler.toastDidFinish(pause: 0, then: loaf.makeMoreToast)
        
        #expect(await waitUntil { !scheduler.isPausingBetweenToasts })
        #expect(!scheduler.isToasting)
        
        loaf.queue = ["B"]
        scheduler.advance(startNext: loaf.makeMoreToast)
        
        #expect(loaf.toasted == ["A", "B"])
    }
}
