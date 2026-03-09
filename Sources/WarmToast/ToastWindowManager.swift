import SwiftUI
import UIKit

@MainActor
final class ToastWindowManager {
    private var window: ToastWindow?
    private var dismissSignal: ToastDismissSignal?
    
    func show<Bread, S: ShapeStyle, Toast: View>(
        bread: Bread,
        options: ToasterSettings<S>,
        toast: @escaping (Bread) -> Toast,
        onDismiss: @escaping () -> Void
    ) {
        if window != nil { tearDown() }
        
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        
        let signal = ToastDismissSignal()
        self.dismissSignal = signal
        
        let hostView = ToastWindowHost(
            dismissSignal: signal,
            bread: bread,
            options: options,
            toast: toast,
            onDismiss: { [weak self] in
                self?.tearDown()
                onDismiss()
            }
        )
        
        let hostingController = UIHostingController(rootView: hostView)
        hostingController.view.backgroundColor = .clear
        
        let toastWindow = ToastWindow(windowScene: scene)
        toastWindow.windowLevel = .alert + 1
        toastWindow.backgroundColor = .clear
        toastWindow.rootViewController = hostingController
        toastWindow.isHidden = false
        self.window = toastWindow
    }
    
    func hide() {
        dismissSignal?.shouldDismiss = true
    }
    
    func cleanup() {
        tearDown()
    }
    
    private func tearDown() {
        window?.isHidden = true
        window = nil
        dismissSignal = nil
    }
}
