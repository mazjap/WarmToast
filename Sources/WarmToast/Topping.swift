import SwiftUI

/// Something extra on top of a slice: a button such as Undo, Retry or Show. Tapping it runs its action
/// and dismisses the toast.
public struct Topping: Sendable {
    /// The button's title.
    public let title: String
    
    /// The button's role, such as `.destructive`.
    public let role: ButtonRole?
    
    let action: @MainActor @Sendable () -> Void
    
    /// Creates a topping.
    /// - Parameters:
    ///   - title: The button's title.
    ///   - role: The button's role, such as `.destructive`.
    ///   - action: Runs when the button is tapped, before the toast is dismissed.
    public init(_ title: String, role: ButtonRole? = nil, action: @escaping @MainActor @Sendable () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }
}

/// Dismisses the toast that the view is in. Read it from the environment in toast content with
/// `@Environment(\.ejectToast)`, then call it: `ejectToast()`.
public struct EjectToastAction: Sendable {
    private let eject: @MainActor @Sendable () -> Void
    
    init(_ eject: @escaping @MainActor @Sendable () -> Void) {
        self.eject = eject
    }
    
    @MainActor
    public func callAsFunction() {
        eject()
    }
}

extension EnvironmentValues {
    /// Dismisses the toast that the view is in. Does nothing outside a toast.
    @Entry public var ejectToast = EjectToastAction {}
}
