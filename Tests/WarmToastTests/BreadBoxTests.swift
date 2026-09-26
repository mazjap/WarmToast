import Foundation
import Testing
@testable import WarmToast

@MainActor
@Suite struct BreadBoxTests {
    /// Toasts the current bread until it leaves, the way a toaster would.
    private func finishCurrentToast<Bread>(in box: BreadBox<Bread>) throws {
        let order = try #require(box.current)
        box.toastDidLeave(orderID: order.id)
    }

    // MARK: - Order

    @Test func toastsTheFirstBreadRightAway() {
        let box = BreadBox<String>()

        box.toast("A")
        box.toast("B")

        #expect(box.toasting == "A")
        #expect(box.waiting == ["B"])
    }

    @Test func toastsTheNextBreadAfterThePause() async throws {
        let box = BreadBox<String>(pauseBetweenToasts: 0.05)
        box.toast("A")
        box.toast("B")

        try finishCurrentToast(in: box)

        #expect(box.toasting == nil)
        #expect(await waitUntil { box.toasting == "B" })
        #expect(box.waiting.isEmpty)
    }

    @Test func breadAddedDuringThePauseWaitsForIt() async throws {
        // Regression from 0.1.0: bread added during the pause must not skip it or another toast.
        let box = BreadBox<String>(pauseBetweenToasts: 0.1)
        box.toast("A")
        try finishCurrentToast(in: box)

        box.toast("B")
        box.toast("C")
        #expect(box.toasting == nil)

        #expect(await waitUntil { box.toasting == "B" })
        #expect(box.waiting == ["C"])
    }

    @Test func staleLeaveIsIgnored() throws {
        let box = BreadBox<String>()
        box.toast("A")
        let order = try #require(box.current)

        box.toastDidLeave(orderID: UUID())

        #expect(box.current?.id == order.id)
    }

    // MARK: - Duplicates

    @Test func ignoresBreadThatIsAlreadyToasting() {
        // TrekPoint's "already waiting" case: tapping repeatedly must not toast the same bread back to back.
        let box = BreadBox<String>()

        box.toast("Offline")
        box.toast("Offline")

        #expect(box.toasting == "Offline")
        #expect(box.waiting.isEmpty)
    }

    @Test func ignoresBreadThatIsAlreadyWaiting() {
        let box = BreadBox<String>()

        box.toast("A")
        box.toast("B")
        box.toast("B")

        #expect(box.waiting == ["B"])
    }

    @Test func replacingTheToastOnScreenKeepsItsPlace() throws {
        let box = BreadBox<String>()
        box.toast("Downloading 10%", recipe: "download")
        let order = try #require(box.current)

        box.toast("Downloading 50%", recipe: "download", ifDuplicate: .replace)

        #expect(box.current?.id == order.id)
        #expect(box.current?.revision == 1)
        #expect(box.toasting == "Downloading 50%")
    }

    @Test func replacingWaitingBreadKeepsItsPlaceInLine() {
        let box = BreadBox<String>()
        box.toast("A")
        box.toast("B 1", recipe: "B")
        box.toast("C")

        box.toast("B 2", recipe: "B", ifDuplicate: .replace)

        #expect(box.waiting == ["B 2", "C"])
    }

    @Test func bumpingWaitingBreadMovesItToTheFront() {
        let box = BreadBox<String>()
        box.toast("A")
        box.toast("B")
        box.toast("C 1", recipe: "C")

        box.toast("C 2", recipe: "C", ifDuplicate: .bump)

        #expect(box.waiting == ["C 2", "B"])
    }

    @Test func toastAgainAllowsDuplicates() {
        let box = BreadBox<String>()

        box.toast("A")
        box.toast("A", ifDuplicate: .toastAgain)

        #expect(box.waiting == ["A"])
    }

    @Test func breadThatIsLeavingIsNotADuplicate() {
        let box = BreadBox<String>()
        box.toast("A")
        box.eject()

        box.toast("A")

        #expect(box.waiting == ["A"])
    }

    @Test func breadWithoutARecipeIsNeverADuplicate() {
        struct Crumb {}
        let box = BreadBox<Crumb>()

        box.toast(Crumb())
        box.toast(Crumb())

        #expect(box.waiting.count == 1)
    }

    // MARK: - Ejecting

    @Test func ejectAsksTheCurrentToastToLeave() {
        let box = BreadBox<String>()
        box.toast("A")

        box.eject()

        #expect(box.isEjecting)
    }

    @Test func ejectWithNothingToastingDoesNothing() {
        let box = BreadBox<String>()

        box.eject()

        #expect(!box.isEjecting)
    }

    @Test func emptyBoxThrowsOutWaitingBreadAndEjects() throws {
        let box = BreadBox<String>(pauseBetweenToasts: 0)
        box.toast("A")
        box.toast("B")

        box.emptyBox()

        #expect(box.waiting.isEmpty)
        #expect(box.isEjecting)

        try finishCurrentToast(in: box)
        #expect(box.isEmpty)
    }
}
