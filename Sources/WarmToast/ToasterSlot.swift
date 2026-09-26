import SwiftUI

/// The slot a toaster pops toast out of: the top or the bottom of the screen.
public enum ToasterSlot: Sendable {
    case top
    case bottom
    
    /// The screen edge the toast slides in from and is swiped away toward.
    var edge: Edge {
        switch self {
        case .top: .top
        case .bottom: .bottom
        }
    }
    
    /// How far a toast follows a vertical drag: only toward its edge.
    func offset(forDrag translation: CGFloat) -> CGFloat {
        switch self {
        case .top: min(0, translation)
        case .bottom: max(0, translation)
        }
    }
    
    /// Whether a drag that ended flings the toast off its edge. A quick flick can end before the toast
    /// moves, so the predicted end of the drag counts too.
    func isDismissal(translation: CGFloat, predictedEndTranslation: CGFloat) -> Bool {
        let threshold: CGFloat = 30
        switch self {
        case .top: return min(translation, predictedEndTranslation) < -threshold
        case .bottom: return max(translation, predictedEndTranslation) > threshold
        }
    }
}
