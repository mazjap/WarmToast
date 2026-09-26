import Testing
@testable import WarmToast

@Suite struct ToasterSlotTests {
    @Test func topToastsOnlyFollowUpwardDrags() {
        #expect(ToasterSlot.top.offset(forDrag: -40) == -40)
        #expect(ToasterSlot.top.offset(forDrag: 40) == 0)
    }
    
    @Test func bottomToastsOnlyFollowDownwardDrags() {
        #expect(ToasterSlot.bottom.offset(forDrag: 40) == 40)
        #expect(ToasterSlot.bottom.offset(forDrag: -40) == 0)
    }
    
    @Test func toastsAreSwipedAwayTowardTheirEdge() {
        #expect(ToasterSlot.top.isDismissal(translation: -50, predictedEndTranslation: -60))
        #expect(!ToasterSlot.top.isDismissal(translation: 50, predictedEndTranslation: 60))
        #expect(ToasterSlot.bottom.isDismissal(translation: 50, predictedEndTranslation: 60))
        #expect(!ToasterSlot.bottom.isDismissal(translation: -50, predictedEndTranslation: -60))
    }
    
    @Test func quickFlicksCountByTheirPredictedEnd() {
        #expect(ToasterSlot.top.isDismissal(translation: -10, predictedEndTranslation: -165))
        #expect(ToasterSlot.bottom.isDismissal(translation: 10, predictedEndTranslation: 165))
    }
    
    @Test func shortDragsDoNotDismiss() {
        #expect(!ToasterSlot.top.isDismissal(translation: -10, predictedEndTranslation: -20))
        #expect(!ToasterSlot.bottom.isDismissal(translation: 10, predictedEndTranslation: 20))
    }
}
