import SwiftUI

// MARK: - Public bread toasting API

extension View {
    public func preheatToaster<Bread, S, Toast>(
        withBread bread: Binding<Bread?>,
        options: ToasterSettings<S>,
        advancedOptions: ToasterInternals = .init(),
        @ViewBuilder toast: @escaping (Bread) -> Toast
    ) -> some View where S: ShapeStyle, Toast: View {
        self.modifier(Toaster(bread: bread, options: options, advancedOptions: advancedOptions, toast: toast))
    }
    
    public func preheatToaster<S, Toast>(
        isToasting: Binding<Bool>,
        options: ToasterSettings<S>,
        advancedOptions: ToasterInternals = .init(),
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
            advancedOptions: advancedOptions
        ) { _ in toast() }
    }
}

// MARK: - Public loaf toasting API

extension View {
    public func preheatToaster<Bread, S, Toast>(
        withLoaf loaf: Binding<[Bread]>,
        options: ToasterSettings<S>,
        advancedOptions: ToasterInternals = .init(),
        durationBetweenToasts: TimeInterval = 1,
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
