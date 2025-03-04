import SwiftUI
import Combine

struct Toaster<Bread, S: ShapeStyle, Toast: View>: ViewModifier {
    @Binding private var bread: Bread?
    @State private var offset = Double.zero
    
    private let options: ToasterSettings<S>
    private let advancedOptions: ToasterInternals
    private let id: UUID?
    private let toast: (Bread) -> Toast
    private let timer: AnyPublisher<Timer.TimerPublisher.Output, Timer.TimerPublisher.Failure>
    
    init(bread: Binding<Bread?>, options: ToasterSettings<S>, advancedOptions: ToasterInternals, id: UUID?, toast: @escaping (Bread) -> Toast) {
        self._bread = bread
        self.toast = toast
        self.options = options
        self.advancedOptions = advancedOptions
        self.id = id
        self.timer = Timer.TimerPublisher(interval: options.timeTilToasted.timeInterval, tolerance: 0.1, runLoop: .main, mode: .common, options: nil).autoconnect().eraseToAnyPublisher()
    }
    
    @ViewBuilder
    private var toastView: some View {
        if let bread {
            let animation = options.animation ?? .default
            
            toast(bread)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    HStack(spacing: 0) {
                        if let accent = options.accentColor {
                            accent
                                .frame(width: 8)
                        }
                        
                        Rectangle()
                            .fill(options.background)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .id(id?.uuidString ?? "toast")
                .offset(y: offset)
                .gesture(DragGesture()
                    .onChanged { value in
                        guard options.isSwipable else { return }
                        
                        offset = min(0, value.translation.height)
                    }
                    .onEnded { value in
                        guard options.isSwipable else { return }
                        
                        if offset < -30 {
                            self.bread = nil
                            offset = 0
                        } else {
                            withAnimation {
                                offset = .zero
                            }
                        }
                    }
                )
                .transition(.toastInsertion(options.presentationStyle, animation: animation))
                .animation(animation)
                .onReceive(timer) { date in
                    if options.timeTilToasted != .indefinitely {
                        self.bread = nil
                    }
                }
        }
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .center) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(toastView.zIndex(advancedOptions.customToastZIndex), alignment: .top)
        }
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
            .edgesIgnoringSafeArea(.all)
            .preheatToaster(
                withBread: $message,
                options: .toasterStrudel(type: .info, duration: .seconds(5)),
                toastId: UUID()
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
