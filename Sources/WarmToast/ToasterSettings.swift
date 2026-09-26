import SwiftUI

public struct ToasterSettings: Sendable {
    /// The duration that the toast is shown on screen in seconds.
    /// - Note: Use `PresentedDuration.indefinitely` to keep the toast on screen forever. The toast can be manually dismissed by the user if `isSwipable` is true.
    public var timeTilToasted: PresentedDuration
    
    /// Color applied to the leading edge of the toast.
    /// - Note: No leading edge color will be shown if nil is provided.
    public var accentColor: Color?
    
    /// The background of the toast.
    /// - Note: `ToastBackground.default` will be used if no parameter is provided.
    public var background: ToastBackground
    
    /// The method with which to insert the toast into the world.
    /// - Note: `PresentationStyle.slide` will be used if none is provided.
    public var presentationStyle: PresentationStyle
    
    /// The animation to use when presenting the toast.
    public var animation: Animation?
    
    /// Whether swipe-to-dismiss is enabled on the toast.
    /// - Note: Defaults to true.
    public var isSwipable: Bool
    
    /// Where the toast pops out: the top or the bottom of the screen.
    /// - Note: Defaults to `.top`.
    public var slot: ToasterSlot
    
    /// Extra space between the toast and the edges of the safe area, for example to keep a toast clear
    /// of a floating control.
    /// - Note: Defaults to no extra space.
    public var insets: EdgeInsets
    
    /// What VoiceOver says when the toast appears. Toasters for slices fill this in from the slice's text.
    /// - Note: Defaults to nil, which announces `String` bread itself and nothing for other bread. Set it
    ///   to an empty string to announce nothing.
    public var announcement: String?
    
    /// How long the toast stays on screen while VoiceOver is running.
    /// - Note: Defaults to nil, which is twice `timeTilToasted`. Toasters for slices with a topping keep
    ///   the toast up until it's dismissed, so there's time to reach the button.
    public var voiceOverDuration: PresentedDuration?
    
    /// ToasterSettings initializer. Also see the static methods such as: `toasterStrudel` for built in options.
    /// - Parameters:
    ///   - timeTilToasted: The duration that the toast is shown on screen in seconds. Use `PresentedDuration.indefinitely` to keep the toast on screen forever. The toast can be manually dismissed by the user if `isSwipable` is true.
    ///   - accentColor: Color applied to the leading edge of the toast. No leading edge color will be shown if nil is provided.
    ///   - background: The background of the toast. Defaults to `ToastBackground.default`, which is `UIColor.systemBackground`.
    ///   - presentationStyle: The method with which to insert the toast into the world. `PresentationStyle.slide` will be used if none is provided.
    ///   - animation: The animation to use when presenting the toast.
    ///   - isSwipable: Whether swipe-to-dismiss is enabled on the toast. Defaults to true.
    ///   - slot: Where the toast pops out: the top or the bottom of the screen. Defaults to `.top`.
    ///   - insets: Extra space between the toast and the edges of the safe area. Defaults to none.
    public init(
        timeTilToasted: PresentedDuration,
        accentColor: Color? = nil,
        background: ToastBackground = .default,
        presentationStyle: PresentationStyle = .slide,
        animation: Animation? = nil,
        isSwipable: Bool = true,
        slot: ToasterSlot = .top,
        insets: EdgeInsets = EdgeInsets()
    ) {
        self.timeTilToasted = timeTilToasted
        self.accentColor = accentColor
        self.background = background
        self.presentationStyle = presentationStyle
        self.animation = animation
        self.isSwipable = isSwipable
        self.slot = slot
        self.insets = insets
    }
}

// MARK: - Accessibility

extension ToasterSettings {
    /// What VoiceOver says when a toast of this bread appears, or nil to say nothing.
    func announcement(for bread: Any) -> String? {
        if let announcement {
            return announcement.isEmpty ? nil : announcement
        }
        guard let text = bread as? String, !text.isEmpty else { return nil }
        return text
    }
    
    /// How long the toast stays on screen, allowing extra time while VoiceOver is running.
    func duration(voiceOverRunning: Bool) -> PresentedDuration {
        guard voiceOverRunning else { return timeTilToasted }
        if let voiceOverDuration {
            return voiceOverDuration
        }
        switch timeTilToasted {
        case .indefinitely:
            return .indefinitely
        case let .seconds(seconds):
            return .seconds(seconds * 2)
        }
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
    ///   - slot: Where the toast pops out: the top or the bottom of the screen. Defaults to `.top`.
    ///   - insets: Extra space between the toast and the edges of the safe area. Defaults to none.
    public init(
        timeTilToasted: PresentedDuration,
        accentColor: Color? = nil,
        background: some ShapeStyle,
        presentationStyle: PresentationStyle = .slide,
        animation: Animation? = nil,
        isSwipable: Bool = true,
        slot: ToasterSlot = .top,
        insets: EdgeInsets = EdgeInsets()
    ) {
        self.init(
            timeTilToasted: timeTilToasted,
            accentColor: accentColor,
            background: .style(background),
            presentationStyle: presentationStyle,
            animation: animation,
            isSwipable: isSwipable,
            slot: slot,
            insets: insets
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
        
        /// The color of the type's icon: the tint's increased-contrast variant, which stays legible on
        /// the default background in light and dark mode. The bright tint is too light for yellow and green.
        var iconTint: Color {
            Color(uiColor: iconUIColor)
        }
        
        var iconUIColor: UIColor {
            uiTint.increasedContrast
        }
        
        private var uiTint: UIColor {
            switch self {
            case .error: .systemRed
            case .warning: .systemYellow
            case .info: .systemBlue
            case .success: .systemGreen
            }
        }
        
        /// How VoiceOver names the type, as the label of a slice's icon.
        public var accessibilityName: String {
            switch self {
            case .error: "Error"
            case .warning: "Warning"
            case .info: "Info"
            case .success: "Success"
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
    public static func toasterStrudel(type: StrudelType?, duration: PresentedDuration = .seconds(5), slot: ToasterSlot = .top) -> ToasterSettings {
        ToasterSettings(
            timeTilToasted: duration,
            accentColor: type?.tint,
            animation: .bouncy,
            slot: slot
        )
    }
    
    public static let plainToasterStrudel = toasterStrudel(type: .info)
}
