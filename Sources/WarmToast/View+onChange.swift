import SwiftUI
import Combine

extension View {
    /// Cross-platform onChange modifier: uses SwiftUI onChange when available, falls back to legacy for iOS/tvOS 13.
    @ViewBuilder
    func onChange<Value: Equatable>(of value: Value, do action: @escaping (Value) -> Void) -> some View {
        if #available(iOS 17, tvOS 17, *) {
            self.onChange(of: value, initial: false) { _, new in
                action(new)
            }
        } else if #available(iOS 14, tvOS 14, *) {
            self.onChange(of: value, perform: action)
        } else {
            self.modifier(OnChangeLegacyModifier(value: value, action: action))
        }
    }
}

private struct OnChangeLegacyModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let action: (Value) -> Void
    @State private var previousValue: Value?
    
    func body(content: Content) -> some View {
        content
            .onReceive(Just(value)) { newValue in
                if let previousValue = previousValue, previousValue != newValue {
                    action(newValue)
                }
                self.previousValue = newValue
            }
    }
}
