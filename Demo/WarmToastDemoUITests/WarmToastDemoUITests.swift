import XCTest

/// Exercises WarmToast in a real app: real scenes, real windows and real touches.
/// The demo's toasts stay on screen for 3 seconds.
@MainActor
final class WarmToastDemoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private var toastMessage: XCUIElement {
        app.staticTexts["toastMessage"]
    }

    private func showToast() {
        app.buttons["showToast"].tap()
        XCTAssertTrue(toastMessage.waitForExistence(timeout: 2), "The toast never appeared")
    }

    private func waitForToastToDisappear(timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: toastMessage)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    // MARK: - Touches

    func testButtonInsideToastReceivesTaps() {
        app.launch()
        showToast()

        app.buttons["undoButton"].tap()

        XCTAssertEqual(app.staticTexts["undoCount"].label, "Undo taps: 1")
        XCTAssertTrue(toastMessage.exists, "Tapping a button inside the toast shouldn't dismiss it")
    }

    func testTouchesOutsideToastReachTheApp() {
        app.launch()
        showToast()

        app.buttons["tapApp"].tap()

        XCTAssertEqual(app.staticTexts["appTapCount"].label, "App taps: 1")
        XCTAssertTrue(toastMessage.exists)
    }

    func testSwipingUpDismissesTheToast() {
        app.launch()
        showToast()

        toastMessage.swipeUp()

        XCTAssertTrue(waitForToastToDisappear(timeout: 1.5), "The toast should leave well before its 3 second countdown")
    }

    // MARK: - Countdown

    func testToastDismissesItselfAfterItsDuration() {
        app.launch()
        showToast()

        XCTAssertTrue(waitForToastToDisappear(timeout: 5))
    }

    func testHoldingTheToastPausesTheCountdown() {
        app.launch()
        showToast()

        // Hold for longer than the toast's whole duration.
        toastMessage.press(forDuration: 5)

        XCTAssertTrue(toastMessage.exists, "The toast was dismissed while it was being held")
        XCTAssertTrue(waitForToastToDisappear(timeout: 5), "The countdown didn't resume after the toast was released")
    }

    // MARK: - Scenes

    func testToastsQueuedInTheBackgroundAppearWhenTheAppReturns() {
        app.launchArguments = ["-queue-when-backgrounded"]
        app.launch()

        // The app queues two toasts as it moves to the background, when its scene isn't active.
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()

        let first = app.staticTexts["Queued in background 1"]
        XCTAssertTrue(first.waitForExistence(timeout: 3), "The toast queued in the background never appeared")

        // The queue must keep going after that toast.
        let second = app.staticTexts["Queued in background 2"]
        XCTAssertTrue(second.waitForExistence(timeout: 6), "The queue stalled after the first toast")
    }
    
    // MARK: - Bread box
    
    func testToppingRunsItsActionAndDismissesTheToast() {
        app.launch()
        app.buttons["showToppingSlice"].tap()
        let title = app.staticTexts["Group merged"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        
        app.buttons["Undo"].tap()
        
        XCTAssertEqual(app.staticTexts["toppingCount"].label, "Topping taps: 1")
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: title)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 1.5), .completed, "The topping didn't dismiss its toast")
    }
    
    func testRepeatedTapsDoNotStackDuplicateToasts() {
        app.launch()
        let button = app.buttons["showOfflineSlice"]
        
        button.tap()
        button.tap()
        button.tap()
        
        XCTAssertTrue(app.staticTexts["You're offline"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["slicesWaiting"].label, "Slices waiting: 0")
    }
    
    func testBottomToastsAreSwipedDown() {
        app.launch()
        app.buttons["showBottomSlice"].tap()
        let title = app.staticTexts["Download finished"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        XCTAssertGreaterThan(title.frame.minY, app.frame.midY, "The toast isn't in the bottom half of the screen")
        
        title.swipeDown()
        
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: title)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 1.5), .completed, "Swiping down didn't dismiss the bottom toast")
    }
    
    func testLoafToastsAppearWhenQueuedAtLaunch() {
        // The toaster presents during the view's first appearance, which once left the toast unrendered.
        app.launchArguments = ["-toast-at-launch"]
        app.launch()
        
        // The loaf toast's text has an identifier, so match it by label.
        let loafToast = app.staticTexts.matching(NSPredicate(format: "label == %@", "Toasted at launch")).firstMatch
        XCTAssertTrue(loafToast.waitForExistence(timeout: 3))
    }
    
    func testBreadBoxToastsAppearWhenQueuedAtLaunch() {
        app.launchArguments = ["-slice-at-launch"]
        app.launch()
        
        XCTAssertTrue(app.staticTexts["Welcome back"].waitForExistence(timeout: 3))
    }
    
    func testSliceToastPassesAnAccessibilityAudit() throws {
        app.launch()
        app.buttons["showToppingSlice"].tap()
        XCTAssertTrue(app.staticTexts["Group merged"].waitForExistence(timeout: 2))
        
        // Contrast is left out: the demo's own plain buttons only nearly pass it.
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription, .textClipped])
    }
}
