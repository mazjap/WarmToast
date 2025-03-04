import SwiftUI
import Combine

struct AutomatedLoafToaster<Bread, S: ShapeStyle, Toast: View>: ViewModifier {
    @State private var isAppearing = true
    @State private var currentlyToasting: Bread? = nil
    @Binding private var loaf: [Bread]
    
    private let options: ToasterSettings<S>
    private let advancedOptions: ToasterInternals
    private let durationBetweenToasts: TimeInterval
    private let toast: (Bread) -> Toast
    
    private var wholeLoaf: [Bread] {
        currentlyToasting.map { [$0] + loaf } ?? loaf
    }
    
    init(loaf: Binding<[Bread]>, options: ToasterSettings<S>, advancedOptions: ToasterInternals, durationBetweenToasts: TimeInterval, toast: @escaping (Bread) -> Toast) {
        self._loaf = loaf
        self.options = options
        self.advancedOptions = advancedOptions
        self.durationBetweenToasts = durationBetweenToasts
        self.toast = toast
    }
    
    func body(content: Content) -> some View {
        content
            .modifier(Toaster(
                bread: $currentlyToasting,
                options: options,
                advancedOptions: advancedOptions,
                toast: toast
            ))
            .onAppear {
                isAppearing = false
                if !loaf.isEmpty {
                    print("making more toast")
                    currentlyToasting = loaf.remove(at: 0)
                }
            }
            // Not ideal, body is called each time the view is redrawn, but onChange isn't supported on iOS 13 :(
            .onReceive(Just(wholeLoaf)) { _ in
                if currentlyToasting == nil && !loaf.isEmpty && !isAppearing {
                    makeMoreToast()
                }
            }
    }
    
    private func makeMoreToast() {
        DispatchQueue.main.asyncAfter(deadline: .now() + durationBetweenToasts) {
            if !loaf.isEmpty {
                currentlyToasting = loaf.remove(at: 0)
            }
        }
    }
}

struct AutomatedLoafToaster_Previews: PreviewProvider {
    struct ToasterPreviewView: View {
        @State var messages = [String]()
        
        var body: some View {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(messages.isEmpty ? "Populate toaster" : "Clear toaster") {
                        if messages.isEmpty {
                            messages = ["Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World, Hello, World", "The fitness graham pacer test", "Uh oh, something went wrong", "I like trains"]
                            print(messages)
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
