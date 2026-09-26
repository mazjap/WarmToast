import Testing
@testable import WarmToast

@MainActor
@Suite struct ToastWindowManagerTests {
    @Test func showsToastRightAwayWhenAWindowIsAvailable() {
        let manager = ToastWindowManager(windowSource: FakeToastWindowSource())
        
        manager.show("Hello")
        
        #expect(manager.window?.isHidden == false)
        #expect(!manager.isPending)
    }
    
    @Test func holdsToastUntilAWindowBecomesAvailable() {
        let source = FakeToastWindowSource(isAvailable: false)
        let manager = ToastWindowManager(windowSource: source)
        let dismissals = CallCounter()
        
        manager.show("Queued in the background", onDismiss: dismissals.increment)
        
        #expect(manager.window == nil)
        #expect(manager.isPending)
        
        source.becomeAvailable()
        
        #expect(manager.window?.isHidden == false)
        #expect(!manager.isPending)
        #expect(dismissals.count == 0)
    }
    
    @Test func hidingAPendingToastReportsItAsDismissed() {
        // A toast that never got a window must still finish, or a queue waiting on it stalls for good.
        let source = FakeToastWindowSource(isAvailable: false)
        let manager = ToastWindowManager(windowSource: source)
        let dismissals = CallCounter()
        
        manager.show("Never shown", onDismiss: dismissals.increment)
        manager.hide()
        
        #expect(dismissals.count == 1)
        #expect(!manager.isPending)
        
        source.becomeAvailable()
        
        #expect(manager.window == nil)
    }
    
    @Test func cleanupDropsAPendingToast() {
        let source = FakeToastWindowSource(isAvailable: false)
        let manager = ToastWindowManager(windowSource: source)
        
        manager.show("Never shown")
        manager.cleanup()
        source.becomeAvailable()
        
        #expect(manager.window == nil)
        #expect(!manager.isPending)
    }
}
