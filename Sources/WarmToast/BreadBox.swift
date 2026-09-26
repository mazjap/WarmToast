import Foundation

/// A box of bread waiting to be toasted. Put bread in with `toast(_:)`, and a toaster attached with
/// `preheatToaster(withBreadBox:)` toasts it one slice at a time.
///
/// Unlike a loaf binding, the box keeps track of the bread that's on screen, so it can tell when the
/// same bread is put in twice.
@MainActor
@Observable
public final class BreadBox<Bread> {
    /// The time between one toast leaving and the next one appearing, in seconds.
    public let pauseBetweenToasts: TimeInterval

    /// The toast being shown, or waiting for a window to be shown in.
    private(set) var current: ToastOrder<Bread>?

    /// Whether the current toast has been asked to leave.
    private(set) var isEjecting = false

    /// Whether the box is waiting out the pause after a toast left.
    private(set) var isPausing = false

    private var line: [ToastOrder<Bread>] = []

    @ObservationIgnored private var pauseTask: Task<Void, Never>?

    /// Creates an empty bread box.
    /// - Parameter pauseBetweenToasts: The time between one toast leaving and the next one appearing, in seconds.
    public init(pauseBetweenToasts: TimeInterval = 0.1) {
        self.pauseBetweenToasts = pauseBetweenToasts
    }

    /// The bread being toasted right now.
    public var toasting: Bread? {
        current?.bread
    }

    /// The bread waiting its turn, in the order it will be toasted.
    public var waiting: [Bread] {
        line.map(\.bread)
    }

    /// Whether there's no bread toasting or waiting.
    public var isEmpty: Bool {
        current == nil && line.isEmpty
    }

    /// Whether the box has nothing to do, including no pause to wait out.
    var isIdle: Bool {
        isEmpty && !isPausing
    }

    /// Puts bread in the box to be toasted after the bread ahead of it.
    /// - Parameters:
    ///   - bread: The bread to toast.
    ///   - options: Settings for this toast only. When nil, the toaster's options are used.
    ///   - recipe: Bread with the same recipe counts as the same bread. When nil, `Hashable` bread is its
    ///     own recipe, a `Slice`'s recipe is its text and type, and other bread is never a duplicate.
    ///   - ifDuplicate: What to do when bread with the same recipe is already toasting or waiting.
    public func toast(
        _ bread: Bread,
        options: ToasterSettings? = nil,
        recipe: AnyHashable? = nil,
        ifDuplicate: DuplicateBread = .ignore
    ) {
        let order = ToastOrder(bread: bread, options: options, recipe: recipe ?? Self.defaultRecipe(for: bread))

        if let recipe = order.recipe, ifDuplicate != .toastAgain {
            // A toast that is already leaving doesn't count as a duplicate.
            if let current, !isEjecting, current.recipe == recipe {
                if ifDuplicate != .ignore {
                    self.current = current.replaced(by: order)
                }
                return
            }

            if let index = line.firstIndex(where: { $0.recipe == recipe }) {
                switch ifDuplicate {
                case .ignore:
                    break
                case .replace:
                    line[index] = line[index].replaced(by: order)
                case .bump:
                    let bumped = line.remove(at: index).replaced(by: order)
                    line.insert(bumped, at: 0)
                case .toastAgain:
                    preconditionFailure("toastAgain never looks for duplicates")
                }
                return
            }
        }

        line.append(order)
        advance()
    }

    /// Dismisses the toast on screen. The next bread in the box is toasted after it leaves.
    public func eject() {
        guard current != nil else { return }
        isEjecting = true
    }

    /// Throws out all the waiting bread and dismisses the toast on screen.
    public func emptyBox() {
        line.removeAll()
        eject()
    }

    /// Called when the current toast has left the screen.
    func toastDidLeave(orderID: UUID) {
        guard current?.id == orderID else { return }

        current = nil
        isEjecting = false
        isPausing = true
        pauseTask?.cancel()

        let pause = pauseBetweenToasts
        pauseTask = Task { [weak self] in
            if pause > 0 {
                try? await Task.sleep(for: .seconds(pause))
            }
            guard !Task.isCancelled, let self else { return }

            self.isPausing = false
            self.advance()
        }
    }

    /// The current order, if it's the one with the given ID.
    func order(withID id: UUID) -> ToastOrder<Bread>? {
        current?.id == id ? current : nil
    }

    private func advance() {
        guard current == nil, !isPausing, !line.isEmpty else { return }
        current = line.removeFirst()
    }

    private static func defaultRecipe(for bread: Bread) -> AnyHashable? {
        if let bread = bread as? any HasRecipe {
            return bread.recipe
        }
        return bread as? AnyHashable
    }
}

/// What a bread box does when bread with the same recipe is already toasting or waiting.
public enum DuplicateBread: Sendable {
    /// Keep the bread that's already in the box and throw the new bread away.
    case ignore

    /// Put the new bread where the old bread was. If the old bread is on screen, the toast shows the new
    /// bread and its countdown starts over.
    case replace

    /// Like `replace`, but waiting bread also moves to the front of the line.
    case bump

    /// Toast the new bread anyway, after the bread ahead of it.
    case toastAgain
}

/// Bread with its own idea of which bread counts as the same.
protocol HasRecipe {
    var recipe: AnyHashable { get }
}

/// One piece of bread in a bread box, with the settings and recipe it was put in with.
struct ToastOrder<Bread> {
    /// Stays the same when the bread is replaced, so the toast on screen can update in place.
    let id: UUID
    var bread: Bread
    var options: ToasterSettings?
    var recipe: AnyHashable?

    /// Goes up each time the bread is replaced.
    var revision = 0

    init(bread: Bread, options: ToasterSettings?, recipe: AnyHashable?) {
        self.id = UUID()
        self.bread = bread
        self.options = options
        self.recipe = recipe
    }

    func replaced(by order: ToastOrder<Bread>) -> ToastOrder<Bread> {
        var replaced = self
        replaced.bread = order.bread
        replaced.options = order.options
        replaced.recipe = order.recipe
        replaced.revision += 1
        return replaced
    }
}
