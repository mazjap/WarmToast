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

    /// Toast from the loaf, in the bottom slot, as soon as the app launches.
    static let toastAtLaunch = "-toast-at-launch"
    
    /// Toast a slice on glass from the bread box as soon as the app launches.
    static let sliceAtLaunch = "-slice-at-launch"
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var loaf: [DemoToast] = []
    @State private var sliceBox = BreadBox<Slice>()
    @State private var undoCount = 0
    @State private var toppingCount = 0
    @State private var appTapCount = 0

    private let arguments = ProcessInfo.processInfo.arguments

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Button("Show toast") {
                loaf.append(DemoToast(text: "Group deleted", hasUndo: true))
            }
            .accessibilityIdentifier("showToast")

            Button("Show offline slice") {
                sliceBox.toast(Slice("You're offline", message: "Maps will update when you reconnect", type: .warning))
            }
            .accessibilityIdentifier("showOfflineSlice")

            Button("Show slice with topping") {
                let topping = Topping("Undo") { toppingCount += 1 }
                sliceBox.toast(Slice("Group merged", type: .info, topping: topping))
            }
            .accessibilityIdentifier("showToppingSlice")

            HStack(spacing: 16) {
                ForEach(ToasterSettings.StrudelType.allCases, id: \.self) { type in
                    Button("\(type)") {
                        sliceBox.toast(Slice("Sync \(type)", message: "Tap Retry to try again", type: type, topping: Topping("Retry") {}))
                    }
                    .accessibilityIdentifier("showToppingSlice-\(type)")
                }
            }
            
            Button("Show bottom slice") {
                sliceBox.toast(Self.downloadFinished, options: Self.bottomGlass(for: Self.downloadFinished))
            }
            .accessibilityIdentifier("showBottomSlice")

            Button("Tap the app") {
                appTapCount += 1
            }
            .accessibilityIdentifier("tapApp")

            Text("App taps: \(appTapCount)")
                .accessibilityIdentifier("appTapCount")

            Text("Undo taps: \(undoCount)")
                .accessibilityIdentifier("undoCount")

            Text("Topping taps: \(toppingCount)")
                .accessibilityIdentifier("toppingCount")

            Text("Slices waiting: \(sliceBox.waiting.count)")
                .accessibilityIdentifier("slicesWaiting")

            Spacer()
        }
        // Text-colored controls, so the accessibility audit's contrast check is about the toasts.
        .tint(.primary)
        .frame(maxWidth: .infinity)
        .onAppear {
            // One toast each: only one toast window at a time is exposed to accessibility.
            if arguments.contains(DemoLaunchArgument.toastAtLaunch) {
                loaf.append(DemoToast(text: "Toasted at launch"))
            }
            if arguments.contains(DemoLaunchArgument.sliceAtLaunch) {
                var options = ToasterSettings.toasterStrudel(type: .success, duration: 30)
                options.background = .glass
                sliceBox.toast(Slice("Welcome back", message: "3 trails synced", type: .success), options: options)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard arguments.contains(DemoLaunchArgument.queueWhenBackgrounded), phase == .background else { return }
            loaf += [
                DemoToast(text: "Queued in background 1"),
                DemoToast(text: "Queued in background 2")
            ]
        }
        .preheatToaster(
            withLoaf: $loaf,
            options: .toasterStrudel(type: .info, duration: 3, slot: arguments.contains(DemoLaunchArgument.toastAtLaunch) ? .bottom : .top),
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
        .preheatToaster(withBreadBox: sliceBox) { slice in
            var options = ToasterSettings.toasterStrudel(for: slice)
            options.timeTilToasted = 3
            return options
        }
    }

    private static let downloadFinished = Slice("Download finished", message: "Yosemite Valley is ready offline", type: .success)

    private static func bottomGlass(for slice: Slice) -> ToasterSettings {
        var options = ToasterSettings.toasterStrudel(for: slice)
        options.slot = .bottom
        options.background = .glass
        options.insets = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        return options
    }
}
