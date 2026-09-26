import SwiftUI
import Testing
@testable import WarmToast

@MainActor
@Suite struct SliceTests {
    @Test func slicesWithTheSameTextAndTypeAreDuplicates() {
        // TrekPoint's repeated taps: the same slice put in twice is toasted once.
        let box = BreadBox<Slice>()
        
        box.toast(Slice("Offline", type: .warning))
        box.toast(Slice("Offline", type: .warning))
        
        #expect(box.waiting.isEmpty)
    }
    
    @Test func slicesWithDifferentTypesAreNotDuplicates() {
        let box = BreadBox<Slice>()
        
        box.toast(Slice("Download", type: .error))
        box.toast(Slice("Download", type: .success))
        
        #expect(box.waiting.count == 1)
    }
    
    @Test func slicesUseAStrudelOfTheirTypeByDefault() {
        #expect(ToasterSettings.toasterStrudel(for: Slice("Saved", type: .success)).accentColor == .green)
        #expect(ToasterSettings.toasterStrudel(for: Slice("Saved")).accentColor == nil)
    }
    
    @Test func toastersForSlicesNeedNoToastClosure() {
        // These only need to compile.
        @State var slice: Slice?
        @State var loaf: [Slice] = []
        let box = BreadBox<Slice>()
        
        _ = Color.clear.preheatToaster(withBread: $slice)
        _ = Color.clear.preheatToaster(withLoaf: $loaf, durationBetweenToasts: 0.5)
        _ = Color.clear.preheatToaster(withBreadBox: box)
        _ = Color.clear.preheatToaster(withBreadBox: box) { _ in .toasterStrudel(type: .info, duration: 10) }
    }
    
    @Test func toppingsDoNotChangeWhichSlicesAreDuplicates() {
        let box = BreadBox<Slice>()
        
        box.toast(Slice("Group deleted", type: .info, topping: Topping("Undo") {}))
        box.toast(Slice("Group deleted", type: .info))
        
        #expect(box.waiting.isEmpty)
        #expect(box.toasting?.topping?.title == "Undo")
    }
}
