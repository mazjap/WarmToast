import SwiftUI
import Testing
@testable import WarmToast

@Suite struct ToasterSettingsTests {
    @Test func reduceMotionFadesInsteadOfSliding() {
        let settings = ToasterSettings(timeTilToasted: .seconds(3), presentationStyle: .slide, animation: .bouncy)
        
        #expect(settings.presentationStyle(reduceMotion: true) == .fade)
        #expect(settings.presentationAnimation(reduceMotion: true) == .easeInOut(duration: 0.2))
    }
    
    @Test func withoutReduceMotionTheChosenStyleIsUsed() {
        let settings = ToasterSettings(timeTilToasted: .seconds(3), presentationStyle: .scale, animation: .bouncy)
        
        #expect(settings.presentationStyle(reduceMotion: false) == .scale)
        #expect(settings.presentationAnimation(reduceMotion: false) == .bouncy)
    }
    
    @Test func withoutACustomAnimationTheDefaultIsUsed() {
        let settings = ToasterSettings(timeTilToasted: .seconds(3))
        
        #expect(settings.presentationAnimation(reduceMotion: false) == .default)
    }
}
