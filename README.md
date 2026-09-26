# WarmToast 🍞

A lightweight toast notification system for SwiftUI applications.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017+-lightgrey.svg)](https://developer.apple.com/swift/)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)

WarmToast makes it incredibly easy to add beautiful, customizable toast notifications to your SwiftUI project. Preheat a toaster, hand it some bread, and it pops out toast: one slice at a time, above everything else in your app.

![WarmToast Demo](./src/demo.gif)

## Features

- 🍞 **Bread Boxes** - An observable queue of toasts that skips duplicates, and can replace or dismiss the toast on screen
- 🥪 **Ready-Made Slices** - Toasts with an icon, title and message for info, success, warning and error, without writing a view
- 🧈 **Toppings** - Buttons on toasts, like Undo, Retry or Show
- 🎨 **Customizable Styling** - Accent colors, backgrounds (including Liquid Glass), animations, and more
- 📍 **Placement** - Toasts pop out of the top or bottom slot, with custom insets
- 👆 **Interactive** - Users can swipe to dismiss toasts, and the countdown pauses while a toast is touched
- ⏱️ **Flexible Durations** - From quick notifications to indefinite presentation
- 🪟 **Always On Top** - Toasts appear above sheets and alerts, and touches around them reach your app
- ♿️ **Accessible** - VoiceOver announcements, extra time and a Dismiss action, and fades instead of slides with Reduce Motion
- 🎯 **SwiftUI Native** - Built specifically for SwiftUI

## Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add WarmToast to your project through Swift Package Manager:

1. In Xcode, select **File** > **Add Packages...**
2. Enter the package repository URL: `https://github.com/mazjap/WarmToast.git`
3. Select the version you want to use

Alternatively, add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/mazjap/WarmToast.git", from: "0.2.0")
]
```

## Usage

### Basic Toast

Show a simple toast notification:

```swift
struct ContentView: View {
    @State private var showToast: Bool = false
    
    var body: some View {
        VStack {
            Button("Show Toast") {
                showToast = true
            }
        }
        .preheatToaster(
            isToasting: $showToast,
            options: .toasterStrudel(type: .info, duration: 3)
        ) {
            Text("This is a toast notification!")
        }
    }
}
```

### Toast with Custom Content

When the bread is set, the toast pops out. If it changes while it's toasting, the toast shows the new bread.

```swift
@State private var message: String? = nil

var body: some View {
    VStack {
        Button("Show Toast") {
            message = "Hello World!"
        }
    }
    .preheatToaster(
        withBread: $message,
        options: .toasterStrudel(type: .info, duration: 5)
    ) { message in
        Text(message)
            .font(.headline)
    }
}
```

### Slices

A `Slice` is ready-made bread: a title, an optional message, and a strudel type that picks the icon and tint. Toasters for slices don't need a toast closure.

```swift
@State private var slice: Slice? = nil

var body: some View {
    Button("Download") {
        slice = Slice("Download finished", message: "Yosemite Valley is ready offline", type: .success)
    }
    .preheatToaster(withBread: $slice)
}
```

### Toppings

Put a button on a slice with a `Topping`. Tapping it runs its action and dismisses the toast.

```swift
slice = Slice(
    "Group deleted",
    type: .info,
    topping: Topping("Undo") {
        restoreGroup()
    }
)
```

Custom toast content can dismiss its own toast, too:

```swift
struct DownloadToast: View {
    @Environment(\.ejectToast) private var ejectToast
    
    var body: some View {
        Button("Show download") {
            showDownload()
            ejectToast()
        }
    }
}
```

### Bread Box

A `BreadBox` is a queue of toasts that you own. It knows which bread is toasting and which is waiting, so it can skip duplicates, replace a toast in place, or clear everything out.

```swift
@State private var breadBox = BreadBox<Slice>()

var body: some View {
    MapView()
        .preheatToaster(withBreadBox: breadBox)
}

func downloadFailed(_ region: String) {
    breadBox.toast(Slice("Download failed", message: region, type: .error))
}
```

Bread with the same recipe counts as the same bread. `Hashable` bread is its own recipe, and slices are the same when their text and type match. Choose what happens to duplicates with `ifDuplicate`:

```swift
// Ignore the new bread if the same bread is toasting or waiting. This is the default.
breadBox.toast(Slice("You're offline", type: .warning))

// Show progress in place, restarting the toast's countdown.
breadBox.toast(Slice("Downloading \(percent)%"), recipe: "download", ifDuplicate: .replace)

// Also move waiting bread to the front of the line.
breadBox.toast(Slice("Sync failed", type: .error), ifDuplicate: .bump)

// Toast it again anyway.
breadBox.toast(Slice("Checkpoint reached", type: .success), ifDuplicate: .toastAgain)
```

`breadBox.eject()` dismisses the toast on screen, and `breadBox.emptyBox()` also throws out the waiting bread. `toasting`, `waiting` and `isEmpty` tell your app what the box holds.

### Toast Queue (Loaf)

Present multiple toasts one after another. Each item in the loaf must be `Identifiable`, and is removed from the loaf when it's toasted:

```swift
struct Message: Identifiable {
    let id = UUID()
    let text: String
}

@State private var messages: [Message] = []

var body: some View {
    VStack {
        Button("Show Toasts") {
            messages = [
                Message(text: "First notification"),
                Message(text: "Second notification"),
                Message(text: "Third notification")
            ]
        }
    }
    .preheatToaster(
        withLoaf: $messages,
        options: .toasterStrudel(type: .info, duration: 2),
        durationBetweenToasts: 0.5
    ) { message in
        Text(message.text)
    }
}
```

### Options for Each Toast

Pass options as a closure to pick them for each piece of bread:

```swift
.preheatToaster(withLoaf: $events, options: { event in
    .toasterStrudel(type: event.isFailure ? .error : .success)
}) { event in
    Text(event.description)
}
```

Bread put in a bread box can bring its own options: `breadBox.toast(bread, options: .toasterStrudel(type: .error))`.

### Custom Styling

Create your own toast style:

```swift
.preheatToaster(
    withBread: $message,
    options: ToasterSettings(
        timeTilToasted: 3,
        accentColor: Color.purple,
        background: Color.black.opacity(0.8),
        presentationStyle: .scale,
        animation: .spring(),
        isSwipable: true
    )
) { message in
    Text(message)
        .foregroundColor(.white)
        .padding(.horizontal)
}
```

The background can be any shape style, like a color, gradient or material, or `.glass` for Liquid Glass on iOS 26. Earlier versions fall back to the regular material.

### Placement

Toasts pop out of the top slot by default. Use the bottom slot, and insets from the safe area, to keep toasts clear of your own controls. Toasts are swiped away toward their slot's edge.

```swift
var options = ToasterSettings.toasterStrudel(type: .success, slot: .bottom)
options.insets = EdgeInsets(top: 0, leading: 16, bottom: 72, trailing: 16)
options.background = .glass
```

## Preset Toast Types

WarmToast comes with four preset toast types that you can use out of the box. Each has a tint and an SF Symbol, which slices use for their icon:

```swift
// Info toast (blue accent)
.toasterStrudel(type: .info)

// Success toast (green accent)
.toasterStrudel(type: .success)

// Warning toast (yellow accent)
.toasterStrudel(type: .warning)

// Error toast (red accent)
.toasterStrudel(type: .error)
```

## Advanced Usage

### Custom Toast Duration

```swift
// 5-second duration
.toasterStrudel(type: .info, duration: 5)

// Indefinite duration (stays until dismissed)
.toasterStrudel(type: .warning, duration: .indefinitely)
```

The countdown pauses while the user touches or drags the toast, and picks up where it left off when they let go.

### Accessibility

- VoiceOver announces a toast's `announcement` when it appears. Slices fill it in from their text. For custom content, set `options.announcement`.
- Toasts have a Dismiss accessibility action and respond to the escape gesture.
- While VoiceOver is running, toasts stay up for `voiceOverDuration`, which defaults to twice their usual time. Slices with a topping stay until they're dismissed.
- With Reduce Motion on, toasts fade in instead of sliding or bouncing.

### Presentation

Toasts are shown in their own window above the rest of your app, including sheets and alerts, in the window scene of the view you attach the toaster to. Touches on the toast go to the toast, and touches anywhere else go to your app.

If that scene isn't active yet (for example, a toast set while the app is in the background), the toast waits and appears once the scene becomes active.

### Known Limitations

Each toaster shows its toasts in a window of its own. When two toasters show a toast at the same time, only one of those windows is exposed to accessibility, so VoiceOver can't move to the other toast, although it's still announced. Use one bread box per screen to avoid this.

## Migrating from 0.1

- The minimum deployment target is iOS 17.
- `ToasterSettings` is no longer generic. Replace `ToasterSettings<Color>` with `ToasterSettings`. Backgrounds that are shape styles still work as before, and `.glass` is new.
- The `timeTilToasted: Double` initializer is gone. Write `timeTilToasted: 3` or `.seconds(duration)`.
- The settings' properties are now `var`, so you can adjust a strudel in place.
- Changing `withBread`'s bread while it's toasting now shows the new bread instead of keeping the old one.

## Examples

Check out the previews in `Previews.swift` for examples of toasting bread, loaves and bread boxes.

The `Demo` folder contains a small app, `Demo/WarmToastDemo.xcodeproj`, whose UI tests check toasts in a real app: touches, swiping, toppings, bottom slots, the countdown pausing while a toast is held, and toasts queued at launch or while the app is in the background.

## License

WarmToast is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

---

Made with ❤️ and SwiftUI. Inspired by [SimpleToast](https://github.com/sanzaru/SimpleToast)
