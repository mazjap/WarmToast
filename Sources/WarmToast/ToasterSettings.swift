import SwiftUI

public struct ToasterSettings: Sendable {
    /// The duration that the toast is shown on screen in seconds.
    /// - Note: Use `PresentedDuration.indefinitely` to keep the toast on screen forever. The toast can be manually dismissed by the user if `isSwipable` is true.
    public let timeTilToasted: PresentedDuration
    
    /// Color applied to the leading edge of the toast.
    /// - Note: No leading edge color will be shown if nil is provided.
    public let accentColor: Color?
    
    /// The background of the toast.
    /// - Note: `ToastBackground.default` will be used if no parameter is provided.
    public let background: ToastBackground
    
    /// The method with which to insert the toast into the world.
    /// - Note: `PresentationStyle.slide` will be used if none is provided.
    public let presentationStyle: PresentationStyle
    
    /// The animation to use when presenting the toast.
    public let animation: Animation?
    
    /// Whether swipe-to-dismiss is enabled on the toast.
    /// - Note: Defaults to true.
    public let isSwipable: Bool
    
    /// ToasterSettings initializer. Also see the static methods such as: `toasterStrudel` for built in options.
    /// - Parameters:
    ///   - timeTilToasted: The duration that the toast is shown on screen in seconds. Use `PresentedDuration.indefinitely` to keep the toast on screen forever. The toast can be manually dismissed by the user if `isSwipable` is true.
    ///   - accentColor: Color applied to the leading edge of the toast. No leading edge color will be shown if nil is provided.
    ///   - background: The background of the toast. Defaults to `ToastBackground.default`, which is `UIColor.systemBackground`.
    ///   - presentationStyle: The method with which to insert the toast into the world. `PresentationStyle.slide` will be used if none is provided.
    ///   - animation: The animation to use when presenting the toast.
    ///   - isSwipable: Whether swipe-to-dismiss is enabled on the toast. Defaults to true.
    public init(
        timeTilToasted: PresentedDuration,
        accentColor: Color? = nil,
        background: ToastBackground = .default,
        presentationStyle: PresentationStyle = .slide,
        animation: Animation? = nil,
        isSwipable: Bool = true
    ) {
        self.timeTilToasted = timeTilToasted
        self.accentColor = accentColor
        self.background = background
        self.presentationStyle = presentationStyle
        self.animation = animation
        self.isSwipable = isSwipable
    }
}

// MARK: - Convenience initializer(s)

extension ToasterSettings {
    /// ToasterSettings initializer that fills the background with a shape style, such as a color or material.
    /// - Parameters:
    ///   - timeTilToasted: The duration that the toast is shown on screen. Use `PresentedDuration.indefinitely` to keep the toast on screen forever. The toast can be manually dismissed by the user if `isSwipable` is true.
    ///   - accentColor: Color applied to the leading edge of the toast. No leading edge color will be shown if nil is provided.
    ///   - background: The shape style to fill the toast's background with.
    ///   - presentationStyle: The method with which to insert the toast into the world. `PresentationStyle.slide` will be used if none is provided.
    ///   - animation: The animation to use when presenting the toast.
    ///   - isSwipable: Whether swipe-to-dismiss is enabled on the toast. Defaults to true.
    public init(
        timeTilToasted: PresentedDuration,
        accentColor: Color? = nil,
        background: some ShapeStyle,
        presentationStyle: PresentationStyle = .slide,
        animation: Animation? = nil,
        isSwipable: Bool = true
    ) {
        self.init(
            timeTilToasted: timeTilToasted,
            accentColor: accentColor,
            background: .style(background),
            presentationStyle: presentationStyle,
            animation: animation,
            isSwipable: isSwipable
        )
    }
}

// MARK: - Motion

extension ToasterSettings {
    /// The presentation style to use, replaced by a fade when Reduce Motion is on.
    func presentationStyle(reduceMotion: Bool) -> PresentationStyle {
        reduceMotion ? .fade : presentationStyle
    }
    
    /// The animation to use, replaced by a short ease without any bounce when Reduce Motion is on.
    func presentationAnimation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : (animation ?? .default)
    }
}

// MARK: - Static properties

extension ToasterSettings {
    /// The kind of news a toast brings, which sets its tint and icon.
    public enum StrudelType: Sendable, CaseIterable {
        case error
        case warning
        case info
        case success
        
        /// The color of the toast's accent bar and icon.
        public var tint: Color {
            switch self {
            case .error: .red
            case .warning: .yellow
            case .info: .blue
            case .success: .green
            }
        }
        
        /// The name of the SF Symbol that represents the type.
        public var symbolName: String {
            switch self {
            case .error: "exclamationmark.octagon.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .info: "info.circle.fill"
            case .success: "checkmark.circle.fill"
            }
        }
    }
    
    /// Ready-made settings with the type's accent color and a bouncy animation.
    public static func toasterStrudel(type: StrudelType?, duration: PresentedDuration = .seconds(5)) -> ToasterSettings {
        ToasterSettings(
            timeTilToasted: duration,
            accentColor: type?.tint,
            animation: .bouncy
        )
    }
    
    public static let plainToasterStrudel = toasterStrudel(type: .info)
}
