import struct Foundation.TimeInterval

public enum PresentedDuration: Sendable, Equatable, ExpressibleByFloatLiteral {
    case indefinitely
    case seconds(TimeInterval)
    
    public init(floatLiteral value: Double) {
        self = .seconds(value)
    }
}
