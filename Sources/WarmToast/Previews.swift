import SwiftUI

private let previewMessages = [
    "Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World",
    "The fitness graham pacer test",
    "Uh oh, something went wrong",
    "I like trains"
]

private struct BreadPreview: View {
    @State private var message: String?
    
    var body: some View {
        Button(message == nil ? "Show toaster" : "Clear toaster") {
            message = message == nil ? previewMessages.randomElement() : nil
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.orange)
        .preheatToaster(withBread: $message, options: .toasterStrudel(type: .info, duration: 5)) { message in
            Text(message)
                .font(.title)
        }
    }
}

private struct LoafPreview: View {
    struct Payload: Identifiable {
        let id = UUID()
        let value: String
    }
    
    @State private var messages = [Payload]()
    
    var body: some View {
        Button(messages.isEmpty ? "Populate toaster" : "Clear toaster") {
            messages = messages.isEmpty ? previewMessages.map { Payload(value: $0) } : []
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.orange)
        .preheatToaster(withLoaf: $messages, options: .toasterStrudel(type: .info, duration: 1)) { message in
            Text(message.value)
                .font(.title)
        }
    }
}

private struct BreadBoxPreview: View {
    @State private var box = BreadBox<String>()
    
    var body: some View {
        VStack(spacing: 16) {
            Button("Toast a random message") {
                box.toast(previewMessages.randomElement()!)
            }
            Button("Eject") {
                box.eject()
            }
            Text("\(box.waiting.count) waiting")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.orange)
        .preheatToaster(withBreadBox: box, options: .toasterStrudel(type: .success, duration: 2)) { message in
            Text(message)
        }
    }
}

#Preview("Bread") {
    BreadPreview()
}

#Preview("Loaf") {
    LoafPreview()
}

#Preview("Bread box") {
    BreadBoxPreview()
}
