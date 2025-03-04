import SwiftUI

extension AnyTransition {
    static func toastInsertion(_ style: PresentationStyle, animation: Animation) -> AnyTransition {
        switch style {
        case .slide:
            .move(edge: .top).combined(with: .opacity).animation(animation)
        case .fade:
            .opacity.combined(with: .opacity).animation(animation)
        case .scale:
            .scale.combined(with: .opacity).animation(animation)
        }
    }
}
