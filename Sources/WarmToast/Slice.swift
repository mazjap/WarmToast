import SwiftUI

/// A ready-made slice of bread: a title, an optional message, and a strudel type that picks the
/// toast's icon and tint. Toasters for slices draw them with `ToastedSlice`, so no toast closure is needed.
public struct Slice: Identifiable, Sendable {
    public let id: UUID

    /// The main line of the toast.
    public var title: String

    /// A second, smaller line under the title.
    public var message: String?

    /// Picks the icon and tint. A slice without a type has neither.
    public var type: ToasterSettings.StrudelType?

    /// A button on the toast, such as Undo or Retry.
    public var topping: Topping?

    /// Creates a slice.
    /// - Parameters:
    ///   - title: The main line of the toast.
    ///   - message: A second, smaller line under the title.
    ///   - type: Picks the icon and tint.
    ///   - topping: A button on the toast, such as Undo or Retry.
    public init(_ title: String, message: String? = nil, type: ToasterSettings.StrudelType? = nil, topping: Topping? = nil) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.type = type
        self.topping = topping
    }
}

extension Slice: HasRecipe {
    /// Slices with the same text and type count as the same bread in a bread box, whatever their topping.
    var recipe: AnyHashable {
        SliceRecipe(title: title, message: message, type: type)
    }

    private struct SliceRecipe: Hashable {
        let title: String
        let message: String?
        let type: ToasterSettings.StrudelType?
    }
}

extension ToasterSettings {
    /// The options toasters use for a slice by default: a toaster strudel of the slice's type that
    /// VoiceOver announces. A slice with a topping stays up while VoiceOver is running until it's dismissed.
    public static func toasterStrudel(for slice: Slice) -> ToasterSettings {
        var settings = ToasterSettings.toasterStrudel(type: slice.type)
        settings.announcement = [slice.title, slice.message].compactMap { $0 }.joined(separator: ". ")
        if slice.topping != nil {
            settings.voiceOverDuration = .indefinitely
        }
        return settings
    }
}

/// Draws a slice as toast: its type's icon, its title, and its message.
public struct ToastedSlice: View {
    private let slice: Slice
    @Environment(\.ejectToast) private var ejectToast

    public init(_ slice: Slice) {
        self.slice = slice
    }

    public var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 10) {
                if let type = slice.type {
                    Image(systemName: type.symbolName)
                        .foregroundStyle(type.tint)
                        .imageScale(.large)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(slice.title)
                        .font(.subheadline.weight(.semibold))

                    if let message = slice.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)

            if let topping = slice.topping {
                Button(role: topping.role) {
                    topping.action()
                    ejectToast()
                } label: {
                    Text(topping.title)
                        .font(.subheadline.weight(.semibold))
                        // A comfortable tap target, even though the text is small.
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .tint(slice.type?.tint)
            }
        }
        .padding(.vertical, 8)
    }
}
