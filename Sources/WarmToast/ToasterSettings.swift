import SwiftUI

public struct ToasterSettings<S: ShapeStyle>: Sendable {
    /// The duration that the toast is shown on screen in seconds.
    /// - Note: Use `PresentedDuration.indefinite` to keep the toast on screen forever. The toast can be manually dismissed by the user if `isSwipable` is true.
    public let timeTilToasted: PresentedDuration
    
    /// Color applied to the leading edge of the toast.
    /// - Note: No leading edge color will be shown if nil is provided.
    public let accentColor: Color?
    
    /// The background color of the toast.
    /// - Note: `Color.white` will be used if no parameter is provided.
    public let background: S
    
    /// The method with which to insert the toast into the world.
    /// - Note: `PresentationStyle.slide` will be used if none is provided.
    public let presentationStyle: PresentationStyle
    
    /// The animation to use when presenting the toast.
    public let animation: Animation?
    
    /// Whether swipe-to-dismiss is enabled on the toast.
    /// - Note: Defaults to true.
    public let isSwipable: Bool
    
    /// ToasterSettings initializer. Also see the static properties such as: `ToasterStrudel` for built in options.
    /// - Parameters:
    ///   - timeTilToasted: The duration that the toast is shown on screen in seconds. Use `PresentedDuration.indefinite` to keep the toast on screen forever. The toast can be manually dismissed by the user if `isSwipable` is true.
    ///   - accentColor: Color applied to the leading edge of the toast. No leading edge color will be shown if nil is provided.
    ///   - background: The background of the toast. Defaults to `Color.warmToastDefaultBackgroundColor`. `Color.clear` can be used as fits your needs. `warmToastDefaultBackgroundColor` is `UIColor.systemBackground` on iOS/tvOS and `NSColor.windowBackgroundColor` on macOS.
    ///   - presentationStyle: The method with which to insert the toast into the world. `PresentationStyle.slide` will be used if none is provided.
    ///   - animation: The animation to use when presenting the toast.
    ///   - isSwipable: Whether swipe-to-dismiss is enabled on the toast. Defaults to true.
    public init(
        timeTilToasted: PresentedDuration,
        accentColor: Color? = nil,
        background: S = Color.warmToastDefaultBackgroundColor,
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
    /// ToasterSettings initializer. Also see the static methods such as: `toasterStrudel` for built in options.
    /// - Parameters:
    ///   - timeTilToasted: The duration that the toast is shown on screen. Use `PresentedDuration.indefinite` to keep the toast on screen forever. The toast can be manually dismissed by the user if `isSwipable` is true.
    ///   - accentColor: Color applied to the leading edge of the toast. No leading edge color will be shown if nil is provided.
    ///   - background: The background of the toast. Defaults to `Color.warmToastDefaultBackgroundColor`. `Color.clear` can be used as fits your needs. `warmToastDefaultBackgroundColor` is `UIColor.systemBackground` on iOS/tvOS and `NSColor.windowBackgroundColor` on macOS.
    ///   - presentationStyle: The method with which to insert the toast into the world. `PresentationStyle.slide` will be used if none is provided.
    ///   - animation: The animation to use when presenting the toast.
    ///   - isSwipable: Whether swipe-to-dismiss is enabled on the toast. Defaults to true.
    @_disfavoredOverload
    public init(
        timeTilToasted: Double,
        accentColor: Color? = nil,
        background: S,
        presentationStyle: PresentationStyle = .slide,
        animation: Animation? = nil,
        isSwipable: Bool = true
    ) {
        self.init(
            timeTilToasted: .seconds(timeTilToasted),
            accentColor: accentColor,
            background: background,
            presentationStyle: presentationStyle,
            animation: animation,
            isSwipable: isSwipable
        )
    }
}


// MARK: - Static properties

extension ToasterSettings where S == Color {
    public enum StrudelType {
        case error
        case warning
        case info
    }
    
    public static func toasterStrudel(type: StrudelType?, duration: PresentedDuration = .seconds(5)) -> ToasterSettings {
        let accentColor: Color? = {
            switch type {
            case .error:
                .red
            case .warning:
                .yellow
            case .info:
                .blue
            case .none:
                nil
            }
        }()
        
        return ToasterSettings(
            timeTilToasted: duration,
            accentColor: accentColor,
            animation: .bouncy
        )
    }
    
    public static let plainToasterStrudel = toasterStrudel(type: .info)
}
