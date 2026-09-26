import Testing
@testable import WarmToast

@Suite struct AccessibilityTests {
    @Test func voiceOverDoublesTheDurationByDefault() {
        let settings = ToasterSettings.toasterStrudel(type: .info, duration: 4)
        
        #expect(settings.duration(voiceOverRunning: false) == .seconds(4))
        #expect(settings.duration(voiceOverRunning: true) == .seconds(8))
    }
    
    @Test func voiceOverDurationCanBeSetExplicitly() {
        var settings = ToasterSettings.toasterStrudel(type: .info, duration: 4)
        settings.voiceOverDuration = 20
        
        #expect(settings.duration(voiceOverRunning: true) == .seconds(20))
        #expect(settings.duration(voiceOverRunning: false) == .seconds(4))
    }
    
    @Test func indefiniteToastsStayIndefiniteForVoiceOver() {
        let settings = ToasterSettings.toasterStrudel(type: .info, duration: .indefinitely)
        
        #expect(settings.duration(voiceOverRunning: true) == .indefinitely)
    }
    
    @Test func slicesAnnounceTheirText() {
        let settings = ToasterSettings.toasterStrudel(for: Slice("Download failed", message: "No connection", type: .error))
        
        #expect(settings.announcement == "Download failed. No connection")
    }
    
    @Test func slicesWithToppingsStayUpForVoiceOver() {
        let withTopping = ToasterSettings.toasterStrudel(for: Slice("Group deleted", topping: Topping("Undo") {}))
        let without = ToasterSettings.toasterStrudel(for: Slice("Group deleted"))
        
        #expect(withTopping.duration(voiceOverRunning: true) == .indefinitely)
        #expect(without.duration(voiceOverRunning: true) == .seconds(10))
    }
}
