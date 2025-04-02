import SwiftUI

#if canImport(UIKit)
import UIKit

typealias NativeColor = UIColor

extension UIColor {
    static let primaryBackground = systemBackground
}
#else
import AppKit

typealias NativeColor = NSColor

extension NSColor {
    static let primaryBackground = windowBackgroundColor
}
#endif


extension Color {
    init(nativeColor: NativeColor) {
        self.init(nativeColor)
    }
    
    /// `UIColor.systemBackground` on iOS/tvOS and `NSColor.windowBackgroundColor` on macOS.
    public static let warmToastDefaultBackgroundColor = Color(nativeColor: .primaryBackground)
}
