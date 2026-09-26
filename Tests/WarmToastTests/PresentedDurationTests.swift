import Testing
@testable import WarmToast

@Suite struct PresentedDurationTests {
    @Test func integerLiteralsAreSeconds() {
        let duration: PresentedDuration = 3
        #expect(duration == .seconds(3))
    }
    
    @Test func floatLiteralsAreSeconds() {
        let duration: PresentedDuration = 2.5
        #expect(duration == .seconds(2.5))
    }
}
