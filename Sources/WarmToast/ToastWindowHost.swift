import SwiftUI

@Observable
final class ToastDismissSignal {
    var shouldDismiss = false
}

struct ToastWindowHost<Bread, S: ShapeStyle, Toast: View>: View {
    @State private var isVisible = false
    @State private var offset: CGFloat = .zero
    @GestureState private var isTouching = false
    @State private var countdown: DismissCountdown
    let dismissSignal: ToastDismissSignal
    
    let bread: Bread
    let options: ToasterSettings<S>
    let toast: (Bread) -> Toast
    let onDismiss: () -> Void
    
    private let presentationStyle: PresentationStyle
    private let animation: Animation
    
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
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        self.presentationStyle = options.presentationStyle(reduceMotion: reduceMotion)
        self.animation = options.presentationAnimation(reduceMotion: reduceMotion)
        self._countdown = State(initialValue: DismissCountdown(duration: options.timeTilToasted))
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
                    .background(ToastHitArea())
                    .offset(y: offset)
                    .simultaneousGesture(
                        // A minimum distance of zero pauses the countdown as soon as the toast is touched.
                        DragGesture(minimumDistance: 0)
                            .updating($isTouching) { _, isTouching, _ in
                                isTouching = true
                            }
                            .onChanged { value in
                                guard options.isSwipable else { return }
                                offset = min(0, value.translation.height)
                            }
                            .onEnded { value in
                                // A quick flick can end before any drag update moves the toast, so
                                // the predicted end of the swipe counts too.
                                let swipe = min(value.translation.height, value.predictedEndTranslation.height)
                                if options.isSwipable && swipe < -30 {
                                    dismiss()
                                }
                            }
                    )
                    .transition(.toastInsertion(presentationStyle, animation: animation))
                    .onAppear {
                        countdown.start(onFinish: dismiss)
                    }
                    .onDisappear {
                        countdown.cancel()
                        onDismiss()
                    }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(animation) { isVisible = true }
        }
        .onChange(of: dismissSignal.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .onChange(of: isTouching) { _, isTouching in
            // Gesture state also resets when the system cancels the touch, which skips onEnded.
            if isTouching {
                countdown.pause()
            } else if isVisible {
                countdown.resume()
                withAnimation { offset = .zero }
            }
        }
    }
    
    private func dismiss() {
        countdown.cancel()
        withAnimation(animation) { isVisible = false }
    }
}
