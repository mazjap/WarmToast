import Testing
import UIKit
@testable import WarmToast

@MainActor
@Suite struct ToastHitTestingTests {
    @Test func touchesOnTheToastReachIt() async throws {
        let manager = ToastWindowManager(windowSource: FakeToastWindowSource())
        manager.show("Tap me")
        try #require(await waitUntil { manager.window != nil })
        let window = try #require(manager.window)
        
        let reportedFrame = await waitUntil { window.toastFrame != nil }
        try #require(reportedFrame)
        let toastFrame = try #require(window.toastFrame)
        
        #expect(toastFrame.width > 0 && toastFrame.height > 0)
        #expect(window.bounds.contains(toastFrame))
        // On iOS 18 and later, SwiftUI returns the hosting view itself for touches on its content.
        #expect(window.hitTest(CGPoint(x: toastFrame.midX, y: toastFrame.midY), with: nil) != nil)
    }
    
    @Test func touchesAroundTheToastPassThrough() async throws {
        let manager = ToastWindowManager(windowSource: FakeToastWindowSource())
        manager.show("Tap me")
        try #require(await waitUntil { manager.window != nil })
        let window = try #require(manager.window)
        
        try #require(await waitUntil { window.toastFrame != nil })
        let toastFrame = try #require(window.toastFrame)
        
        #expect(window.hitTest(CGPoint(x: window.bounds.midX, y: toastFrame.maxY + 100), with: nil) == nil)
        #expect(window.hitTest(CGPoint(x: toastFrame.minX - 1, y: toastFrame.midY), with: nil) == nil)
    }
    
    @Test func toastFrameAccountsForTheSafeArea() async throws {
        let manager = ToastWindowManager(windowSource: FakeToastWindowSource())
        manager.show("Tap me")
        try #require(await waitUntil { manager.window != nil })
        let window = try #require(manager.window)
        let hostingController = try #require(window.rootViewController)
        hostingController.additionalSafeAreaInsets = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        
        try #require(await waitUntil { (window.toastFrame?.minY ?? 0) >= 60 })
        let toastFrame = try #require(window.toastFrame)
        
        #expect(window.hitTest(CGPoint(x: toastFrame.midX, y: toastFrame.midY), with: nil) != nil)
        // Where the toast would be without the safe area, touches must pass through.
        #expect(window.hitTest(CGPoint(x: toastFrame.midX, y: 20), with: nil) == nil)
    }
    
    @Test func windowWithoutAToastLetsEveryTouchThrough() {
        let window = ToastWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = UIViewController()
        window.isHidden = false
        
        #expect(window.hitTest(CGPoint(x: 200, y: 50), with: nil) == nil)
    }
}
