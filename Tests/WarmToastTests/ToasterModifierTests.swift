import SwiftUI
import Testing
@testable import WarmToast

/// End-to-end tests of the toaster modifiers, through real SwiftUI hosting and toast windows.
/// Serialized because the harness replaces the default window source.
@MainActor
@Suite(.serialized) struct ToasterModifierTests {
    // MARK: - Bread box
    
    @Test func breadBoxToastsAppearAndLeaveInOrder() async throws {
        let box = BreadBox<String>(pauseBetweenToasts: 0)
        let harness = ToasterHarness {
            Color.clear.preheatToaster(withBreadBox: box, options: .toasterStrudel(type: .info, duration: .indefinitely)) { Text($0) }
        }
        defer { harness.tearDown() }
        
        box.toast("A")
        box.toast("B")
        #expect(await waitUntil { harness.visibleToastWindow?.toastFrame != nil })
        
        box.eject()
        #expect(await waitUntil { box.toasting == "B" })
        #expect(await waitUntil { harness.source.madeWindows.count == 2 && harness.visibleToastWindow != nil })
        
        box.eject()
        #expect(await waitUntil { box.isEmpty })
        #expect(await waitUntil { harness.visibleToastWindow == nil })
    }
    
    @Test func replacingBreadUpdatesTheToastInPlace() async throws {
        let box = BreadBox<String>()
        let harness = ToasterHarness {
            Color.clear.preheatToaster(withBreadBox: box, options: .toasterStrudel(type: .info, duration: .indefinitely)) { Text($0) }
        }
        defer { harness.tearDown() }
        
        box.toast("10%", recipe: "download")
        #expect(await waitUntil { harness.visibleToastWindow?.toastFrame != nil })
        
        box.toast("50%", recipe: "download", ifDuplicate: .replace)
        try await Task.sleep(for: .milliseconds(200))
        
        #expect(box.toasting == "50%")
        #expect(harness.source.madeWindows.count == 1)
        #expect(harness.visibleToastWindow != nil)
    }
    
    @Test func toasterLeavingTheScreenDoesNotStallTheBox() async throws {
        // Without a toaster the toast can't leave on its own, so the box must be told it's gone.
        let box = BreadBox<String>(pauseBetweenToasts: 0)
        let showsToaster = BindingBox(true)
        let harness = ToasterHarness {
            ShowWhile(showsToaster) {
                Color.clear.preheatToaster(withBreadBox: box, options: .toasterStrudel(type: .info, duration: .indefinitely)) { Text($0) }
            }
        }
        defer { harness.tearDown() }
        
        box.toast("A")
        box.toast("B")
        #expect(await waitUntil { harness.visibleToastWindow != nil })
        
        showsToaster.value = false
        
        #expect(await waitUntil { box.toasting == "B" })
    }
    
    @Test func ejectingBeforeTheToastRendersStillEndsIt() async throws {
        // Regression: a dismissal requested before the toast window's first render was never seen,
        // so the toast stayed up and the box stalled.
        let box = BreadBox<String>(pauseBetweenToasts: 0)
        let harness = ToasterHarness {
            Color.clear.preheatToaster(withBreadBox: box, options: .toasterStrudel(type: .info, duration: .indefinitely)) { Text($0) }
        }
        defer { harness.tearDown() }
        try await Task.sleep(for: .milliseconds(100))
        
        box.toast("A")
        #expect(await waitUntil { harness.source.madeWindows.count == 1 })
        box.eject()
        
        #expect(await waitUntil { box.isEmpty })
        #expect(await waitUntil { harness.visibleToastWindow == nil })
    }
    
    // MARK: - Bread binding
    
    @Test func bindingIsClearedWhenTheToastLeaves() async throws {
        let bread = BindingBox<String?>(nil)
        let harness = ToasterHarness {
            StateHost(remote: bread) { Color.clear.preheatToaster(withBread: $0, options: .toasterStrudel(type: .info, duration: .seconds(0.2))) { Text($0) } }
        }
        defer { harness.tearDown() }
        try await Task.sleep(for: .milliseconds(100))
        
        bread.value = "Saved"
        #expect(await waitUntil { harness.visibleToastWindow != nil })
        
        #expect(await waitUntil { bread.value == nil })
        #expect(await waitUntil { harness.visibleToastWindow == nil })
    }
    
    @Test func changingTheBreadReplacesTheToastOnScreen() async throws {
        // Regression: changing non-nil bread to other non-nil bread was ignored, so the toast kept the old bread.
        let bread = BindingBox<String?>(nil)
        let harness = ToasterHarness {
            StateHost(remote: bread) { Color.clear.preheatToaster(withBread: $0, options: .toasterStrudel(type: .info, duration: .indefinitely)) { Text($0) } }
        }
        defer { harness.tearDown() }
        try await Task.sleep(for: .milliseconds(100))
        
        bread.value = "A"
        #expect(await waitUntil { harness.visibleToastWindow?.toastFrame != nil })
        let firstFrame = try #require(harness.visibleToastWindow?.toastFrame)
        
        bread.value = "A much longer piece of bread"
        
        // Same window, wider toast.
        #expect(await waitUntil { (harness.visibleToastWindow?.toastFrame?.width ?? 0) > firstFrame.width })
        #expect(harness.source.madeWindows.count == 1)
    }
    
    @Test func settingTheBindingToNilDismissesTheToast() async throws {
        let bread = BindingBox<String?>(nil)
        let harness = ToasterHarness {
            StateHost(remote: bread) { Color.clear.preheatToaster(withBread: $0, options: .toasterStrudel(type: .info, duration: .indefinitely)) { Text($0) } }
        }
        defer { harness.tearDown() }
        try await Task.sleep(for: .milliseconds(100))
        
        bread.value = "A"
        #expect(await waitUntil { harness.visibleToastWindow != nil })
        
        bread.value = nil
        
        #expect(await waitUntil { harness.visibleToastWindow == nil })
    }
    
    // MARK: - Loaf binding
    
    @Test func loafIsToastedOneSliceAtATime() async throws {
        struct Slice: Identifiable, Equatable {
            let id = UUID()
            let text: String
        }
        let loaf = BindingBox([Slice]())
        let harness = ToasterHarness {
            StateHost(remote: loaf) { Color.clear.preheatToaster(withLoaf: $0, options: .toasterStrudel(type: .info, duration: .seconds(0.2)), durationBetweenToasts: 0) { Text($0.text) } }
        }
        defer { harness.tearDown() }
        try await Task.sleep(for: .milliseconds(100))
        
        loaf.value = [Slice(text: "A"), Slice(text: "B")]
        #expect(await waitUntil { harness.source.madeWindows.count == 1 })
        #expect(loaf.value.map(\.text) == ["B"])
        
        #expect(await waitUntil { harness.source.madeWindows.count == 2 })
        #expect(loaf.value.isEmpty)
        
        #expect(await waitUntil { harness.visibleToastWindow == nil })
    }
}

/// Holds a value outside SwiftUI so tests can drive a binding and observe it.
@MainActor
@Observable
final class BindingBox<Value> {
    var value: Value
    
    init(_ value: Value) {
        self.value = value
    }
    
    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}

/// Owns a value in `@State`, the way an app would, and keeps it in sync with `remote` so tests can
/// drive and observe it through a real state binding.
private struct StateHost<Value: Equatable, Content: View>: View {
    let remote: BindingBox<Value>
    let content: (Binding<Value>) -> Content
    @State private var value: Value
    
    init(remote: BindingBox<Value>, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self.remote = remote
        self.content = content
        self._value = State(initialValue: remote.value)
    }
    
    var body: some View {
        content($value)
            .onAppear { value = remote.value }
            .onChange(of: remote.value) { _, newValue in value = newValue }
            .onChange(of: value) { _, newValue in remote.value = newValue }
    }
}

/// Shows its content only while the box holds true.
private struct ShowWhile<Content: View>: View {
    let isShowing: BindingBox<Bool>
    let content: Content
    
    init(_ isShowing: BindingBox<Bool>, @ViewBuilder content: () -> Content) {
        self.isShowing = isShowing
        self.content = content()
    }
    
    var body: some View {
        if isShowing.value {
            content
        }
    }
}
