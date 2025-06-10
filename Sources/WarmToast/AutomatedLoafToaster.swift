import SwiftUI
import Combine

struct AutomatedLoafToaster<Bread: Identifiable, S: ShapeStyle, Toast: View>: ViewModifier {
    @State private var isAppearing = true
    @State private var currentlyToasting: Bread? = nil
    @State private var id: UUID? = nil
    @Binding private var loaf: [Bread]
    
    private let options: ToasterSettings<S>
    private let advancedOptions: ToasterInternals
    private let durationBetweenToasts: TimeInterval
    private let toast: (Bread) -> Toast
    
    init(loaf: Binding<[Bread]>, options: ToasterSettings<S>, advancedOptions: ToasterInternals, durationBetweenToasts: TimeInterval, toast: @escaping (Bread) -> Toast) {
        self._loaf = loaf
        self.options = options
        self.advancedOptions = advancedOptions
        self.durationBetweenToasts = durationBetweenToasts
        self.toast = toast
    }
    
    func body(content: Content) -> some View {
        let breadBinding = Binding {
            currentlyToasting
        } set: {
            currentlyToasting = $0
            
            if currentlyToasting == nil {
                id = nil
            }
        }
        
        content
            .modifier(Toaster(
                bread: breadBinding,
                options: options,
                advancedOptions: advancedOptions,
                id: id,
                toast: toast,
                onDisappear: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + durationBetweenToasts) {
                        decideWhetherToMakeMoreToastNowOrLater()
                    }
                }
            ))
            .onAppear {
                isAppearing = false
                decideWhetherToMakeMoreToastNowOrLater()
            }
            .onChange(of: loaf.map(\.id)) { _ in
                if currentlyToasting == nil && !loaf.isEmpty && !isAppearing {
                    decideWhetherToMakeMoreToastNowOrLater()
                }
            }
    }
    
    private func decideWhetherToMakeMoreToastNowOrLater() {
        if currentlyToasting == nil { // Show the toast immediately
            makeMoreToast()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + durationBetweenToasts) { // Show the toast with a delay
                makeMoreToast()
            }
        }
    }
    
    private func makeMoreToast() {
        if !loaf.isEmpty {
            currentlyToasting = loaf.removeFirst()
            id = UUID()
        }
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
            .edgesIgnoringSafeArea(.all)
            .preheatToaster(
                withLoaf: $messages,
                options: .toasterStrudel(type: .info, duration: .seconds(1))
            ) { message in
                Text(message.value)
                    .font(.title)
            }
        }
    }
    
    static var previews: some View {
        ToasterPreviewView()
    }
}
