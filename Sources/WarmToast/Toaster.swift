import SwiftUI

struct Toaster<Bread, S: ShapeStyle, Toast: View>: ViewModifier {
    @Binding private var bread: Bread?
    @State private var windowManager = ToastWindowManager()
    
    private let options: ToasterSettings<S>
    private let toast: (Bread) -> Toast
    private let onDisappear: (() -> Void)?
    
    init(bread: Binding<Bread?>, options: ToasterSettings<S>, toast: @escaping (Bread) -> Toast, onDisappear: (() -> Void)? = nil) {
        self._bread = bread
        self.toast = toast
        self.onDisappear = onDisappear
        self.options = options
    }
    
    func body(content: Content) -> some View {
        content
            .background(SceneReader { scene in
                windowManager.hostSceneDidChange(scene)
            })
            .onAppear {
                guard let bread else { return }
                show(bread)
            }
            .onDisappear {
                windowManager.cleanup()
            }
            .onChange(of: bread != nil) { _, isNonNil in
                if isNonNil, let currentBread = bread {
                    show(currentBread)
                } else {
                    windowManager.hide()
                }
            }
    }

    private func show(_ bread: Bread) {
        windowManager.show(bread: bread, options: options, toast: toast, onDismiss: {
            self.bread = nil
            self.onDisappear?()
        })
    }
}

struct Toaster_Previews: PreviewProvider {
    struct ToasterPreviewView: View {
        @State var message: String?
        
        var body: some View {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(message == nil ? "Show toaster" : "Clear toaster") {
                        if message == nil {
                            message = ["Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World", "The fitness graham pacer test", "Uh oh, something went wrong", "I like trains"].randomElement()!
                        } else {
                            message = nil
                        }
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            .background(Color.orange)
            .ignoresSafeArea()
            .preheatToaster(
                withBread: $message,
                options: .toasterStrudel(type: .info, duration: .seconds(5))
            ) { message in
                Text(message)
                    .font(.title)
            }
        }
    }
    
    static var previews: some View {
        ToasterPreviewView()
    }
}
