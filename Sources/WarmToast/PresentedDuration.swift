import struct Foundation.TimeInterval

/// How long a toast stays on screen. Write a number of seconds, such as `3` or `2.5`, or use `.indefinitely`.
public enum PresentedDuration: Sendable, Equatable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    case indefinitely
    case seconds(TimeInterval)
    
    public init(floatLiteral value: Double) {
        self = .seconds(value)
    }
    
    public init(integerLiteral value: Int) {
        self = .seconds(TimeInterval(value))
    }
}
