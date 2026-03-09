import SwiftUI
import Combine

final class ToastDismissSignal: ObservableObject {
    @Published var shouldDismiss = false
}

struct ToastWindowHost<Bread, S: ShapeStyle, Toast: View>: View {
    @State private var isVisible = false
    @State private var offset: CGFloat = .zero
    @ObservedObject var dismissSignal: ToastDismissSignal
    
    let bread: Bread
    let options: ToasterSettings<S>
    let toast: (Bread) -> Toast
    let onDismiss: () -> Void
    
    private let animation: Animation
    private let timer: AnyPublisher<Timer.TimerPublisher.Output, Timer.TimerPublisher.Failure>
    
    init(
        dismissSignal: ToastDismissSignal,
        bread: Bread,
        options: ToasterSettings<S>,
        toast: @escaping (Bread) -> Toast,
        onDismiss: @escaping () -> Void
    ) {
        self.dismissSignal = dismissSignal
        self.bread = bread
        self.options = options
        self.toast = toast
        self.onDismiss = onDismiss
        self.animation = options.animation ?? .default
        self.timer = Timer.TimerPublisher(
            interval: options.timeTilToasted.timeInterval,
            tolerance: 0.1,
            runLoop: .main,
            mode: .common,
            options: nil
        ).autoconnect().eraseToAnyPublisher()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isVisible {
                toast(bread)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        HStack(spacing: 0) {
                            if let accent = options.accentColor {
                                accent.frame(width: 8)
                            }
                            Rectangle().fill(options.background)
                        }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
                    .offset(y: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard options.isSwipable else { return }
                                offset = min(0, value.translation.height)
                            }
                            .onEnded { value in
                                guard options.isSwipable else { return }
                                if offset < -30 {
                                    dismiss()
                                } else {
                                    withAnimation { offset = .zero }
                                }
                            }
                    )
                    .transition(.toastInsertion(options.presentationStyle, animation: animation))
                    .onReceive(timer) { _ in
                        guard options.timeTilToasted != .indefinitely else { return }
                        dismiss()
                    }
                    .onDisappear {
                        onDismiss()
                    }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(animation) { isVisible = true }
        }
        .onChange(of: dismissSignal.shouldDismiss, do: { should in
            if should { dismiss() }
        })
    }
    
    private func dismiss() {
        withAnimation(animation) { isVisible = false }
    }
}
