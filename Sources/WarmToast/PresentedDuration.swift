import struct Foundation.TimeInterval

public enum PresentedDuration: Sendable, Equatable, ExpressibleByFloatLiteral {
    case indefinitely
    case seconds(TimeInterval)
    
    internal var timeInterval: TimeInterval {
        switch self {
        case .indefinitely:
            return .greatestFiniteMagnitude
        case let .seconds(seconds):
            return seconds
        }
    }
    
    public init(floatLiteral value: Double) {
        self = .seconds(value)
    }
}
