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

    /// Creates a slice.
    /// - Parameters:
    ///   - title: The main line of the toast.
    ///   - message: A second, smaller line under the title.
    ///   - type: Picks the icon and tint.
    public init(_ title: String, message: String? = nil, type: ToasterSettings.StrudelType? = nil) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.type = type
    }
}

extension Slice: HasRecipe {
    /// Slices with the same text and type count as the same bread in a bread box.
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
    /// The options toasters use for a slice by default: a toaster strudel of the slice's type.
    public static func toasterStrudel(for slice: Slice) -> ToasterSettings {
        .toasterStrudel(type: slice.type)
    }
}

/// Draws a slice as toast: its type's icon, its title, and its message.
public struct ToastedSlice: View {
    private let slice: Slice

    public init(_ slice: Slice) {
        self.slice = slice
    }

    public var body: some View {
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
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
