import SwiftUI

final class ToastDismissSignal: ObservableObject {
    @Published var shouldDismiss = false
}

struct ToastWindowHost<Bread, S: ShapeStyle, Toast: View>: View {
    @State private var isVisible = false
    @State private var offset: CGFloat = .zero
    @State private var countdown: DismissCountdown
    @ObservedObject var dismissSignal: ToastDismissSignal
    
    let bread: Bread
    let options: ToasterSettings<S>
    let toast: (Bread) -> Toast
    let onToastFrameChange: (CGRect?) -> Void
    let onDismiss: () -> Void
    
    private let presentationStyle: PresentationStyle
    private let animation: Animation
    
    init(
        dismissSignal: ToastDismissSignal,
        bread: Bread,
        options: ToasterSettings<S>,
        toast: @escaping (Bread) -> Toast,
        onToastFrameChange: @escaping (CGRect?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.dismissSignal = dismissSignal
        self.bread = bread
        self.options = options
        self.toast = toast
        self.onToastFrameChange = onToastFrameChange
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
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: ToastFramePreferenceKey.self, value: proxy.frame(in: .global))
                    })
                    .offset(y: offset)
                    .simultaneousGesture(
                        // A minimum distance of zero pauses the countdown as soon as the toast is touched.
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                countdown.pause()
                                guard options.isSwipable else { return }
                                offset = min(0, value.translation.height)
                            }
                            .onEnded { value in
                                if options.isSwipable && offset < -30 {
                                    dismiss()
                                } else {
                                    countdown.resume()
                                    withAnimation { offset = .zero }
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
        .onPreferenceChange(ToastFramePreferenceKey.self) { frame in
            onToastFrameChange(frame)
        }
        .onAppear {
            withAnimation(animation) { isVisible = true }
        }
        .onChange(of: dismissSignal.shouldDismiss, do: { should in
            if should { dismiss() }
        })
    }
    
    private func dismiss() {
        countdown.cancel()
        withAnimation(animation) { isVisible = false }
    }
}

private struct ToastFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect? = nil
    
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}
