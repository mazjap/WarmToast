import SwiftUI

/// What a toast is drawn on.
public struct ToastBackground: Sendable {
    enum Storage: Sendable {
        case style(AnyShapeStyle)
    }
    
    let storage: Storage
    
    /// A background filled with any shape style, such as a color, gradient or material.
    public static func style(_ style: some ShapeStyle) -> ToastBackground {
        ToastBackground(storage: .style(AnyShapeStyle(style)))
    }
    
    /// `Color.warmToastDefaultBackgroundColor`, which adapts to light and dark mode.
    public static let `default` = ToastBackground.style(Color.warmToastDefaultBackgroundColor)
}

/// Draws a toast's background and accent bar.
struct ToastBackgroundView: View {
    let background: ToastBackground
    let accentColor: Color?
    
    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
    
    var body: some View {
        fill
            .overlay(alignment: .leading) {
                if let accentColor {
                    accentColor.frame(width: 8)
                }
            }
            .clipShape(shape)
    }
    
    @ViewBuilder
    private var fill: some View {
        switch background.storage {
        case let .style(style):
            shape.fill(style)
        }
    }
}
