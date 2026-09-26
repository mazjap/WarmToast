import SwiftUI

extension AnyTransition {
    static func toastInsertion(_ style: PresentationStyle, from edge: Edge, animation: Animation) -> AnyTransition {
        switch style {
        case .slide:
            .move(edge: edge).combined(with: .opacity).animation(animation)
        case .fade:
            .opacity.animation(animation)
        case .scale:
            .scale.combined(with: .opacity).animation(animation)
        }
    }
}
