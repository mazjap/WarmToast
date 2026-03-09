import SwiftUI

// MARK: - Public bread toasting API

extension View {
    /// Warm up the toaster to prepare for presentation.
    /// - Parameters:
    ///   - bread: Optional item as source of truth for presenting the toast. When non-nil, toast pops out of the toaster. When nil, the toast is removed from the view-hierarchy.
    ///   - options: Toaster options.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<Bread, S, Toast>(
        withBread bread: Binding<Bread?>,
        options: ToasterSettings<S>,
        @ViewBuilder toast: @escaping (Bread) -> Toast
    ) -> some View where S: ShapeStyle, Toast: View {
        self.modifier(Toaster(bread: bread, options: options, toast: toast))
    }
    
    /// Warm up the toaster to prepare for presentation.
    /// - Parameters:
    ///   - isToasting: Whether or not the toaster has popped out some toast.
    ///   - options: Toaster options.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<S, Toast>(
        isToasting: Binding<Bool>,
        options: ToasterSettings<S>,
        @ViewBuilder toast: @escaping () -> Toast
    ) -> some View where S: ShapeStyle, Toast: View {
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
    ///   - loaf: A queue of items to toast one at a time.
    ///   - options: Toaster options.
    ///   - durationBetweenToasts: The time before the next toast is presented after one has dismissed in seconds. Defaults to 0.1.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<Bread: Identifiable, S, Toast>(
        withLoaf loaf: Binding<[Bread]>,
        options: ToasterSettings<S>,
        durationBetweenToasts: TimeInterval = 0.1,
        @ViewBuilder toast: @escaping (Bread) -> Toast
    ) -> some View where S: ShapeStyle, Toast: View {
        self.modifier(AutomatedLoafToaster(
            loaf: loaf,
            options: options,
            durationBetweenToasts: durationBetweenToasts,
            toast: toast
        ))
    }
}
