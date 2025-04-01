# WarmToast 🍞

A lightweight toast notification system for SwiftUI applications.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2013+%20|%20macOS%2010.15+%20|%20tvOS%2013+-lightgrey.svg)](https://developer.apple.com/swift/)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)

WarmToast makes it incredibly easy to add beautiful, customizable toast notifications to your SwiftUI project. With support for multiple presentation styles, accent colors, and automatic toast queuing, you can enhance your app's user experience with minimal code.

![WarmToast Demo](./src/demo.gif)

## Features

- 🎨 **Customizable Styling** - Accent colors, backgrounds, animations, and more
- 🔄 **Multiple Presentation Styles** - Slide, fade, or scale
- 📚 **Toast Queuing** - Automatically present a series of toasts one after another
- 🔄 **Swipeable Dismissal** - Users can swipe to dismiss toasts
- ⏱️ **Flexible Durations** - From quick notifications to indefinite presentation
- 📱 **Cross-Platform** - Works on iOS, macOS, and tvOS
- 🎯 **SwiftUI Native** - Built specifically for SwiftUI

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+
- Swift 6.0+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add WarmToast to your project through Swift Package Manager:

1. In Xcode, select **File** > **Add Packages...**
2. Enter the package repository URL: `https://github.com/mazjap/WarmToast.git`
3. Select the version you want to use

Alternatively, add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/mazjap/WarmToast.git", from: <The latest version>)
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
            options: .toasterStrudel(type: .info, duration: .seconds(3))
        ) {
            Text("This is a toast notification!")
        }
    }
}
```

### Toast with Custom Content

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
        options: .toasterStrudel(type: .info, duration: .seconds(5))
    ) { message in
        Text(message)
            .font(.headline)
    }
}
```

### Toast Queue (Loaf)

Present multiple toasts one after another:

```swift
@State private var messages: [String] = []

var body: some View {
    VStack {
        Button("Show Toasts") {
            messages = [
                "First notification",
                "Second notification",
                "Third notification"
            ]
        }
    }
    .preheatToaster(
        withLoaf: $messages,
        options: .toasterStrudel(type: .info, duration: .seconds(2)),
        durationBetweenToasts: 0.5
    ) { message in
        Text(message)
    }
}
```

### Custom Styling

Create your own toast style:

```swift
.preheatToaster(
    withBread: $message,
    options: ToasterSettings(
        timeTilToasted: .seconds(3),
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

## Preset Toast Types

WarmToast comes with three preset toast types that you can use out of the box:

```swift
// Info toast (blue accent)
.toasterStrudel(type: .info)

// Warning toast (yellow accent)
.toasterStrudel(type: .warning)

// Error toast (red accent)
.toasterStrudel(type: .error)
```

## Advanced Usage

### Custom Toast Duration

```swift
// 5-second duration
.toasterStrudel(type: .info, duration: .seconds(5))

// Indefinite duration (stays until dismissed)
.toasterStrudel(type: .warning, duration: .indefinitely)
```

### Custom Z-Index

When working with complex view hierarchies, you might need to adjust the toast's z-index:

```swift
.preheatToaster(
    withBread: $message,
    options: .toasterStrudel(type: .info),
    advancedOptions: ToasterInternals(customToastZIndex: 100)
) { message in
    Text(message)
}
```

## Examples

Check out the project's preview providers for more examples of how to use WarmToast:

- `Toaster_Previews`: For basic toast usage
- `AutomatedLoafToaster_Previews`: For working with toast queues

## License

WarmToast is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

---

Made with ❤️ and SwiftUI. Inspired by [SimpleToast](https://github.com/sanzaru/SimpleToast)
