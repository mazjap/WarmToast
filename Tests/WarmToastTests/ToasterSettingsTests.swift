import SwiftUI
import UIKit
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

@Suite struct ToastBackgroundTests {
    @Test func settingsAcceptAnyShapeStyleAsTheBackground() {
        // These only need to compile: the settings type no longer carries the style's type.
        let settings: [ToasterSettings] = [
            ToasterSettings(timeTilToasted: 3, background: Color.black.opacity(0.8)),
            ToasterSettings(timeTilToasted: 3, background: .regularMaterial),
            ToasterSettings(timeTilToasted: 3, background: LinearGradient(colors: [.red, .blue], startPoint: .top, endPoint: .bottom)),
            ToasterSettings(timeTilToasted: 3),
            ToasterSettings(timeTilToasted: 3, background: .glass),
        ]
        
        #expect(settings.count == 5)
    }
}

@Suite struct StrudelTypeTests {
    @Test func successStrudelIsGreen() {
        #expect(ToasterSettings.toasterStrudel(type: .success).accentColor == .green)
    }
    
    @Test func everyTypeHasASymbolThatExists() {
        for type in ToasterSettings.StrudelType.allCases {
            #expect(UIImage(systemName: type.symbolName) != nil, "\(type) uses a missing symbol")
        }
    }
    
    @Test func plainStrudelHasNoAccent() {
        #expect(ToasterSettings.toasterStrudel(type: nil).accentColor == nil)
    }
}
