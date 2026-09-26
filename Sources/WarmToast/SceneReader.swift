import SwiftUI
import UIKit

/// Reports the window scene that the view is displayed in.
struct SceneReader: UIViewRepresentable {
    let onChange: (UIWindowScene?) -> Void

    func makeUIView(context: Context) -> SceneReaderView {
        let view = SceneReaderView()
        view.isUserInteractionEnabled = false
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: SceneReaderView, context: Context) {
        uiView.onChange = onChange
    }
}

final class SceneReaderView: UIView {
    var onChange: ((UIWindowScene?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onChange?(window?.windowScene)
    }
}
