import SwiftUI
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
    
    @Test func staleDisappearanceDoesNotDismissTheNextToast() throws {
        let manager = ToastWindowManager(windowSource: FakeToastWindowSource())
        let firstDismissals = CallCounter()
        let secondDismissals = CallCounter()
        
        manager.show("First", onDismiss: firstDismissals.increment)
        let firstID = try #require(manager.presentationID)
        manager.show("Second", onDismiss: secondDismissals.increment)
        let secondWindow = try #require(manager.window)
        
        // The first window's content reports its disappearance after it was replaced.
        manager.toastDidDisappear(presentationID: firstID)
        
        #expect(manager.window === secondWindow)
        #expect(secondWindow.isHidden == false)
        #expect(firstDismissals.count == 0)
        #expect(secondDismissals.count == 0)
    }
    
    @Test func currentDisappearanceDismissesTheToast() throws {
        let manager = ToastWindowManager(windowSource: FakeToastWindowSource())
        let dismissals = CallCounter()
        
        manager.show("Hello", onDismiss: dismissals.increment)
        let window = try #require(manager.window)
        manager.toastDidDisappear(presentationID: try #require(manager.presentationID))
        
        #expect(dismissals.count == 1)
        #expect(window.isHidden)
        #expect(manager.window == nil)
    }
    
    @Test func timedToastDismissesItselfAndReportsIt() async {
        let manager = ToastWindowManager(windowSource: FakeToastWindowSource())
        let dismissals = CallCounter()
        
        manager.show(
            bread: "Short",
            options: .toasterStrudel(type: .info, duration: .seconds(0.1)),
            toast: { Text($0) },
            onDismiss: dismissals.increment
        )
        
        #expect(await waitUntil { dismissals.count == 1 })
        #expect(manager.window == nil)
    }
    
    @Test func hidingAShownToastDismissesItAndReportsIt() async throws {
        let manager = ToastWindowManager(windowSource: FakeToastWindowSource())
        let dismissals = CallCounter()
        
        manager.show("Hello", onDismiss: dismissals.increment)
        let window = try #require(manager.window)
        try #require(await waitUntil { window.toastFrame != nil })
        
        manager.hide()
        
        #expect(await waitUntil { dismissals.count == 1 })
        #expect(window.isHidden)
    }
}
