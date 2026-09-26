import SwiftUI

/// Presents the toasts from a bread box, one at a time, in a window above the view.
struct BreadBoxToaster<Bread, Toast: View>: ViewModifier {
    let box: BreadBox<Bread>
    let options: (Bread) -> ToasterSettings
    let toast: (Bread) -> Toast
    
    @State private var windowManager = ToastWindowManager()
    @State private var presentedOrderID: UUID?
    
    func body(content: Content) -> some View {
        content
            .background(SceneReader { scene in
                windowManager.hostSceneDidChange(scene)
            })
            .onAppear {
                presentCurrentOrder()
            }
            .onDisappear {
                windowManager.cleanup()
                // Without a toaster, the toast can't leave on its own, and the box would stall.
                if let presentedOrderID {
                    self.presentedOrderID = nil
                    box.toastDidLeave(orderID: presentedOrderID)
                }
            }
            .onChange(of: box.current?.id) {
                presentCurrentOrder()
            }
            .onChange(of: box.isLeaving) { _, isLeaving in
                if isLeaving {
                    windowManager.hide()
                }
            }
    }
    
    private func presentCurrentOrder() {
        guard let order = box.current, order.id != presentedOrderID else { return }
        
        presentedOrderID = order.id
        windowManager.show(
            onDismiss: {
                if presentedOrderID == order.id {
                    presentedOrderID = nil
                }
                box.toastDidLeave(orderID: order.id)
            },
            makeHost: { [box, options, toast] dismissSignal, didDisappear in
                ToastWindowHost(
                    box: box,
                    order: order,
                    options: options,
                    toast: toast,
                    dismissSignal: dismissSignal,
                    onDisappear: didDisappear
                )
            }
        )
        
        if box.isLeaving {
            windowManager.hide()
        }
    }
}

/// Toasts a binding's bread whenever it's non-nil, and sets the binding back to nil when the toast leaves.
struct BreadToaster<Bread, Toast: View>: ViewModifier {
    @Binding var bread: Bread?
    let options: (Bread) -> ToasterSettings
    let toast: (Bread) -> Toast
    
    @State private var box = BreadBox<Bread>(pauseBetweenToasts: 0)
    
    /// Every piece of bread from the binding shares one recipe, so new bread replaces the toast on screen.
    private static var recipe: AnyHashable { "WarmToast.BreadToaster" }
    
    func body(content: Content) -> some View {
        content
            .modifier(BreadBoxToaster(box: box, options: options, toast: toast))
            .onAppear {
                toastBread()
            }
            .onChange(of: BreadIdentity(bread)) {
                toastBread()
            }
            .onChange(of: box.isEmpty) { _, isEmpty in
                if isEmpty {
                    bread = nil
                }
            }
    }
    
    private func toastBread() {
        if let bread {
            box.toast(bread, recipe: Self.recipe, ifDuplicate: .replace)
        } else {
            box.emptyBox()
        }
    }
}

/// Moves bread from a loaf binding into a bread box one piece at a time, when the box has nothing to do.
struct LoafToaster<Bread: Identifiable, Toast: View>: ViewModifier {
    @Binding var loaf: [Bread]
    let options: (Bread) -> ToasterSettings
    let toast: (Bread) -> Toast
    
    @State private var box: BreadBox<Bread>
    
    init(
        loaf: Binding<[Bread]>,
        durationBetweenToasts: TimeInterval,
        options: @escaping (Bread) -> ToasterSettings,
        toast: @escaping (Bread) -> Toast
    ) {
        self._loaf = loaf
        self.options = options
        self.toast = toast
        self._box = State(initialValue: BreadBox(pauseBetweenToasts: durationBetweenToasts))
    }
    
    func body(content: Content) -> some View {
        content
            .modifier(BreadBoxToaster(box: box, options: options, toast: toast))
            .onAppear {
                toastNextSlice()
            }
            .onChange(of: loaf.map(\.id)) {
                toastNextSlice()
            }
            .onChange(of: box.isIdle) {
                toastNextSlice()
            }
    }
    
    private func toastNextSlice() {
        guard box.isIdle, !loaf.isEmpty else { return }
        box.toast(loaf.removeFirst(), ifDuplicate: .toastAgain)
    }
}

/// Compares bread for `onChange`, even when the bread type isn't `Equatable`.
///
/// `Equatable` bread is compared by value, `Identifiable` bread by id, and class instances by identity.
/// Other bread can only be told apart from nil, so replacing it with different bread isn't noticed.
struct BreadIdentity<Bread>: Equatable {
    let bread: Bread?
    
    init(_ bread: Bread?) {
        self.bread = bread
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.bread, rhs.bread) {
        case (nil, nil):
            true
        case let (lhs?, rhs?):
            isSameBread(lhs, rhs)
        default:
            false
        }
    }
    
    private static func isSameBread(_ lhs: Bread, _ rhs: Bread) -> Bool {
        if let lhs = lhs as? any Equatable {
            return lhs.isEqual(to: rhs)
        }
        if let lhs = lhs as? any Identifiable {
            return lhs.hasSameID(as: rhs)
        }
        if type(of: lhs) is AnyClass {
            return (lhs as AnyObject) === (rhs as AnyObject)
        }
        return true
    }
}

private extension Equatable {
    func isEqual(to other: Any) -> Bool {
        (other as? Self) == self
    }
}

private extension Identifiable {
    func hasSameID(as other: Any) -> Bool {
        guard let other = other as? Self else { return false }
        return id == other.id
    }
}
