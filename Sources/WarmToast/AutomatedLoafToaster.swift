import SwiftUI

struct AutomatedLoafToaster<Bread: Identifiable, S: ShapeStyle, Toast: View>: ViewModifier {
    @State private var scheduler = LoafScheduler()
    @State private var currentlyToasting: Bread? = nil
    @Binding private var loaf: [Bread]
    
    private let options: ToasterSettings<S>
    private let durationBetweenToasts: TimeInterval
    private let toast: (Bread) -> Toast
    
    init(loaf: Binding<[Bread]>, options: ToasterSettings<S>, durationBetweenToasts: TimeInterval, toast: @escaping (Bread) -> Toast) {
        self._loaf = loaf
        self.options = options
        self.durationBetweenToasts = durationBetweenToasts
        self.toast = toast
    }
    
    func body(content: Content) -> some View {
        let breadBinding = Binding {
            currentlyToasting
        } set: {
            currentlyToasting = $0
        }
        
        content
            .modifier(Toaster(
                bread: breadBinding,
                options: options,
                toast: toast,
                onDisappear: {
                    scheduler.toastDidFinish(pause: durationBetweenToasts, then: makeMoreToast)
                }
            ))
            .onAppear {
                scheduler.advance(startNext: makeMoreToast)
            }
            .onChange(of: loaf.map(\.id)) {
                scheduler.advance(startNext: makeMoreToast)
            }
    }
    
    private func makeMoreToast() -> Bool {
        guard !loaf.isEmpty else { return false }
        currentlyToasting = loaf.removeFirst()
        return true
    }
}

struct AutomatedLoafToaster_Previews: PreviewProvider {
    struct Payload: Identifiable {
        let value: String
        let id = UUID()
        
        init(_ string: String) {
            self.value = string
        }
    }
    
    struct ToasterPreviewView: View {
        @State var messages = [Payload]()
        
        var body: some View {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(messages.isEmpty ? "Populate toaster" : "Clear toaster") {
                        if messages.isEmpty {
                            messages = (Bool.random() ? [
                                "Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World",
                                "The fitness graham pacer test",
                                "Uh oh, something went wrong",
                                "I like trains"
                            ] : (1...20).map {
                                String($0)
                            }).map { Payload($0) }
                        } else {
                            messages = []
                        }
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            .background(Color.orange)
            .ignoresSafeArea()
            .preheatToaster(
                withLoaf: $messages,
                options: .toasterStrudel(type: .info, duration: .seconds(1))
            ) { message in
                Text(message.value)
                    .font(.title)
            }
            .sheet(isPresented: .constant(true)) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        Button(messages.isEmpty ? "Populate toaster" : "Clear toaster") {
                            if messages.isEmpty {
                                messages = (Bool.random() ? [
                                    "Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World",
                                    "The fitness graham pacer test",
                                    "Uh oh, something went wrong",
                                    "I like trains"
                                ] : (1...20).map {
                                    String($0)
                                }).map { Payload($0) }
                            } else {
                                messages = []
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    static var previews: some View {
        ToasterPreviewView()
    }
}
