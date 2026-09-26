import SwiftUI

@Observable
final class ToastDismissSignal {
    var shouldDismiss = false
}

/// The root view of a toast window. It shows one order from a bread box, and updates in place when
/// that order's bread is replaced.
struct ToastWindowHost<Bread, Toast: View>: View {
    @State private var isVisible = false
    @State private var offset: CGFloat = .zero
    @GestureState private var isTouching = false
    @State private var countdown = DismissCountdown()

    let box: BreadBox<Bread>
    let orderID: UUID
    let options: (Bread) -> ToasterSettings
    let toast: (Bread) -> Toast
    let dismissSignal: ToastDismissSignal
    let onDisappear: () -> Void

    private let presentationStyle: PresentationStyle
    private let animation: Animation
    private let slot: ToasterSlot

    init(
        box: BreadBox<Bread>,
        order: ToastOrder<Bread>,
        options: @escaping (Bread) -> ToasterSettings,
        toast: @escaping (Bread) -> Toast,
        dismissSignal: ToastDismissSignal,
        onDisappear: @escaping () -> Void
    ) {
        self.box = box
        self.orderID = order.id
        self.options = options
        self.toast = toast
        self.dismissSignal = dismissSignal
        self.onDisappear = onDisappear

        // The transition is fixed when the toast appears, even if its bread is replaced later.
        let settings = order.options ?? options(order.bread)
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        self.presentationStyle = settings.presentationStyle(reduceMotion: reduceMotion)
        self.animation = settings.presentationAnimation(reduceMotion: reduceMotion)
        self.slot = settings.slot
    }

    var body: some View {
        VStack(spacing: 0) {
            if slot == .bottom {
                Spacer()
            }
            
            if isVisible, let order = box.order(withID: orderID) {
                let settings = order.options ?? options(order.bread)

                toast(order.bread)
                    .environment(\.ejectToast, EjectToastAction { dismiss() })
                    .accessibilityAction(.escape) { dismiss() }
                    .accessibilityAction(named: Text("Dismiss")) { dismiss() }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(ToastBackgroundView(background: settings.background, accentColor: settings.accentColor))
                    .background(ToastHitArea())
                    .offset(y: offset)
                    .simultaneousGesture(
                        // A minimum distance of zero pauses the countdown as soon as the toast is touched.
                        DragGesture(minimumDistance: 0)
                            .updating($isTouching) { _, isTouching, _ in
                                isTouching = true
                            }
                            .onChanged { value in
                                guard settings.isSwipable else { return }
                                offset = slot.offset(forDrag: value.translation.height)
                            }
                            .onEnded { value in
                                let isDismissal = slot.isDismissal(
                                    translation: value.translation.height,
                                    predictedEndTranslation: value.predictedEndTranslation.height
                                )
                                if settings.isSwipable && isDismissal {
                                    dismiss()
                                }
                            }
                    )
                    .padding(settings.insets)
                    .transition(.toastInsertion(presentationStyle, from: slot.edge, animation: animation))
                    .onAppear {
                        startCountdown(settings)
                        announce(order.bread, settings: settings)
                    }
                    .onChange(of: order.revision) {
                        // Replaced bread gets the full time of its own settings.
                        startCountdown(settings)
                        if isTouching {
                            countdown.pause()
                        }
                        announce(order.bread, settings: settings)
                    }
                    .onDisappear {
                        countdown.cancel()
                        onDisappear()
                    }
            }
            
            if slot == .top {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // A toast dismissed before its window first rendered never appears, so onChange
            // below never sees the dismissal. It's done straight away.
            guard !dismissSignal.shouldDismiss else {
                onDisappear()
                return
            }
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

    private func startCountdown(_ settings: ToasterSettings) {
        let duration = settings.duration(voiceOverRunning: UIAccessibility.isVoiceOverRunning)
        countdown.start(duration: duration, onFinish: dismiss)
    }
    
    private func announce(_ bread: Bread, settings: ToasterSettings) {
        guard let announcement = settings.announcement(for: bread) else { return }
        AccessibilityNotification.Announcement(announcement).post()
    }
    
    private func dismiss() {
        countdown.cancel()
        // The box stops treating the toast as current, so new bread isn't mistaken for a duplicate
        // while this one animates out.
        box.toastWillLeave(orderID: orderID)
        withAnimation(animation) { isVisible = false }
    }
}
