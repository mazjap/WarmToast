import SwiftUI

// MARK: - Public bread toasting API

extension View {
    /// Warm up the toaster to prepare for presentation.
    /// - Parameters:
    ///   - bread: Optional item as source of truth for presenting the toast. When non-nil, toast pops out of the toaster. When nil, the toast is removed from the view-hierarchy.
    ///   - options: Toaster options.
    ///   - advancedOptions: Advanced options for the toaster. If not included in initializer, it will use `ToasterInternals`' default initializer.
    ///   - toastId: An id to apply to the toast view. Only useful if you're quickly showing toasts, one after the other. Use state (@State/@Binding) to store the id. If you initialized a UUID in-place, it will change everytime the view is redrawn, which is ineffecient.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<Bread, S, Toast>(
        withBread bread: Binding<Bread?>,
        options: ToasterSettings<S>,
        advancedOptions: ToasterInternals = .init(),
        toastId: UUID? = nil,
        @ViewBuilder toast: @escaping (Bread) -> Toast
    ) -> some View where S: ShapeStyle, Toast: View {
        self.modifier(Toaster(bread: bread, options: options, advancedOptions: advancedOptions, id: toastId, toast: toast))
    }
    
    /// Warm up the toaster to prepare for presentation.
    /// - Parameters:
    ///   - isToasting: Whether or not the toaster has popped out some toast.
    ///   - options: Toaster options.
    ///   - advancedOptions: Advanced options for the toaster. If not included in initializer, it will use `ToasterInternals`' default initializer.
    ///   - toastId: An id to apply to the toast view. Only useful if you're quickly showing toasts, one after the other. Use state (@State/@Binding) to store the id. If you initialized a UUID in-place, it will change everytime the view is redrawn, which is ineffecient.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<S, Toast>(
        isToasting: Binding<Bool>,
        options: ToasterSettings<S>,
        advancedOptions: ToasterInternals = .init(),
        toastId: UUID? = nil,
        @ViewBuilder toast: @escaping () -> Toast
    ) -> some View where S: ShapeStyle, Toast: View {
        let binding = Binding<Bool?> {
            isToasting.wrappedValue ? true : nil
        } set: {
            if $0 == nil {
                isToasting.wrappedValue = false
            }
        }
        
        return self.preheatToaster(
            withBread: binding,
            options: options,
            advancedOptions: advancedOptions,
            toastId: toastId
        ) { _ in toast() }
    }
}

// MARK: - Public loaf toasting API

extension View {
    /// Warm up the toaster to prepare for presentation.
    /// - Parameters:
    ///   - loaf: Whether or not the toaster has popped out some toast.
    ///   - options: Toaster options.
    ///   - advancedOptions: Advanced options for the toaster. If not included in initializer, it will use `ToasterInternals`' default initializer.
    ///   - durationBetweenToasts: The time in seconds after one toast begins dismissal before the next is presented. Because it's from the beginning of the dismissal, it's recommended to use at least 0.25.
    ///   - toast: A view closure that turns bread into toast.
    /// - Returns: Your view with a toaster attached, just out of sight.
    public func preheatToaster<Bread, S, Toast>(
        withLoaf loaf: Binding<[Bread]>,
        options: ToasterSettings<S>,
        advancedOptions: ToasterInternals = .init(),
        durationBetweenToasts: TimeInterval = 0.5,
        @ViewBuilder toast: @escaping (Bread) -> Toast
    ) -> some View where S: ShapeStyle, Toast: View {
        self.modifier(AutomatedLoafToaster(
            loaf: loaf,
            options: options,
            advancedOptions: advancedOptions,
            durationBetweenToasts: durationBetweenToasts,
            toast: toast
        ))
    }
}
