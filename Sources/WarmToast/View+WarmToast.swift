import SwiftUI

// MARK: - Public bread toasting API

extension View {
    /// Warm up the toaster to prepare for presentation.
    /// - Parameters:
    ///   - bread: Optional item as source of truth for presenting the toast. When non-nil, toast pops out of the toaster. When nil, the toast is removed from the view-hierarchy.
    ///     If the bread changes while it's being toasted, the toast shows the new bread. Changes are noticed for `Equatable` bread and class instances.
    ///   - options: Toaster options.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<Bread, Toast: View>(
        withBread bread: Binding<Bread?>,
        options: ToasterSettings,
        @ViewBuilder toast: @escaping (Bread) -> Toast
    ) -> some View {
        self.modifier(BreadToaster(bread: bread, options: { _ in options }, toast: toast))
    }

    /// Warm up the toaster to prepare for presentation.
    /// - Parameters:
    ///   - isToasting: Whether or not the toaster has popped out some toast.
    ///   - options: Toaster options.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<Toast: View>(
        isToasting: Binding<Bool>,
        options: ToasterSettings,
        @ViewBuilder toast: @escaping () -> Toast
    ) -> some View {
        let binding = Binding<Bool?> {
            isToasting.wrappedValue ? true : nil
        } set: {
            if $0 == nil {
                isToasting.wrappedValue = false
            }
        }

        return self.preheatToaster(withBread: binding, options: options) { _ in toast() }
    }
}

// MARK: - Public loaf toasting API

extension View {
    /// Warm up the toaster to prepare for presentation.
    /// - Parameters:
    ///   - loaf: A queue of items to toast one at a time. Each item is removed from the loaf when it's toasted.
    ///   - options: Toaster options.
    ///   - durationBetweenToasts: The time before the next toast is presented after one has dismissed in seconds. Defaults to 0.1.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<Bread: Identifiable, Toast: View>(
        withLoaf loaf: Binding<[Bread]>,
        options: ToasterSettings,
        durationBetweenToasts: TimeInterval = 0.1,
        @ViewBuilder toast: @escaping (Bread) -> Toast
    ) -> some View {
        self.modifier(LoafToaster(
            loaf: loaf,
            durationBetweenToasts: durationBetweenToasts,
            options: { _ in options },
            toast: toast
        ))
    }
}

// MARK: - Public bread box toasting API

extension View {
    /// Warm up the toaster to toast the bread from a bread box, one piece at a time.
    /// - Parameters:
    ///   - breadBox: The box to take bread from. Put bread in with `BreadBox.toast(_:options:recipe:ifDuplicate:)`.
    ///   - options: Toaster options for bread that was put in the box without its own.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<Bread, Toast: View>(
        withBreadBox breadBox: BreadBox<Bread>,
        options: ToasterSettings,
        @ViewBuilder toast: @escaping (Bread) -> Toast
    ) -> some View {
        self.modifier(BreadBoxToaster(box: breadBox, options: { _ in options }, toast: toast))
    }
}
