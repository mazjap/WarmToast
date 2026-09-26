import SwiftUI
import WarmToast

struct DemoToast: Identifiable {
    let id = UUID()
    let text: String
    var hasUndo = false
}

/// Launch arguments the UI tests use to set up a scenario.
enum DemoLaunchArgument {
    /// Queue two toasts when the app moves to the background.
    static let queueWhenBackgrounded = "-queue-when-backgrounded"
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var loaf: [DemoToast] = []
    @State private var undoCount = 0
    @State private var appTapCount = 0

    private let queuesWhenBackgrounded = ProcessInfo.processInfo.arguments.contains(DemoLaunchArgument.queueWhenBackgrounded)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Button("Show toast") {
                loaf.append(DemoToast(text: "Group deleted", hasUndo: true))
            }
            .accessibilityIdentifier("showToast")

            Button("Tap the app") {
                appTapCount += 1
            }
            .accessibilityIdentifier("tapApp")

            Text("App taps: \(appTapCount)")
                .accessibilityIdentifier("appTapCount")

            Text("Undo taps: \(undoCount)")
                .accessibilityIdentifier("undoCount")

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onChange(of: scenePhase) { _, phase in
            guard queuesWhenBackgrounded, phase == .background else { return }
            loaf += [
                DemoToast(text: "Queued in background 1"),
                DemoToast(text: "Queued in background 2")
            ]
        }
        .preheatToaster(
            withLoaf: $loaf,
            options: .toasterStrudel(type: .info, duration: .seconds(3)),
            durationBetweenToasts: 0.5
        ) { toast in
            HStack(spacing: 16) {
                Text(toast.text)
                    .accessibilityIdentifier("toastMessage")

                if toast.hasUndo {
                    Button("Undo") {
                        undoCount += 1
                    }
                    .accessibilityIdentifier("undoButton")
                }
            }
            .padding(.vertical, 12)
        }
    }
}
