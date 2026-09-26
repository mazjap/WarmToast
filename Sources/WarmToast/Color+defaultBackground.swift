import SwiftUI
import UIKit

extension Color {
    /// `UIColor.systemBackground`.
    public static let warmToastDefaultBackgroundColor = Color(UIColor.systemBackground)
}

extension UIColor {
    /// The color's increased-contrast variant, in light and dark mode, whatever the Increase Contrast
    /// setting. Toasts use it for icons and small text that must stay legible on the default background.
    var increasedContrast: UIColor {
        UIColor { traits in
            self.resolvedColor(with: traits.modifyingTraits { $0.accessibilityContrast = .high })
        }
    }
}
