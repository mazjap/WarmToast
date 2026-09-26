import SwiftUI
import Testing
import UIKit
@testable import WarmToast

/// Checks colors against WCAG contrast minimums: 4.5:1 for text and 3:1 for icons.
@MainActor
@Suite struct ContrastTests {
    private func luminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linear(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
    
    // Takes UIColor rather than Color: on iOS 17.0, converting a SwiftUI Color back to UIColor loses its
    // dark-mode variant.
    private func contrast(_ foreground: UIColor, on background: UIColor, in style: UIUserInterfaceStyle) -> CGFloat {
        let traits = UITraitCollection(userInterfaceStyle: style)
        let front = luminance(foreground.resolvedColor(with: traits))
        let back = luminance(background.resolvedColor(with: traits))
        return (max(front, back) + 0.05) / (min(front, back) + 0.05)
    }
    
    @Test(arguments: ToasterSettings.StrudelType.allCases, [UIUserInterfaceStyle.light, .dark])
    func sliceIconsAreLegibleOnTheDefaultBackground(type: ToasterSettings.StrudelType, style: UIUserInterfaceStyle) {
        // Regression: the icon used the bright tint, and yellow on white is about 1.5:1.
        let ratio = contrast(type.iconUIColor, on: .systemBackground, in: style)
        #expect(ratio >= 3, "\(type) icon contrast is \(ratio):1")
    }
    
    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func sliceMessagesAreLegibleOnTheDefaultBackground(style: UIUserInterfaceStyle) {
        // The regular secondary gray falls just short of 4.5:1 for small text.
        let ratio = contrast(UIColor.secondaryLabel.increasedContrast, on: .systemBackground, in: style)
        #expect(ratio >= 4.5, "Message contrast is \(ratio):1")
    }
}
