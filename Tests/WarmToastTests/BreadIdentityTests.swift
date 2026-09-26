import Testing
@testable import WarmToast

@Suite struct BreadIdentityTests {
    @Test func equatableBreadIsComparedByValue() {
        #expect(BreadIdentity("A") == BreadIdentity("A"))
        #expect(BreadIdentity("A") != BreadIdentity("B"))
    }
    
    @Test func identifiableBreadIsComparedById() {
        // Regression: Slice isn't Equatable, so any two slices counted as the same bread, and changing a
        // slice binding to another slice never showed the new one.
        let first = Slice("First")
        let second = Slice("Second")
        
        #expect(BreadIdentity(first) == BreadIdentity(first))
        #expect(BreadIdentity(first) != BreadIdentity(second))
    }
    
    @Test func classInstancesAreComparedByIdentity() {
        final class Crust {}
        let crust = Crust()
        
        #expect(BreadIdentity(crust) == BreadIdentity(crust))
        #expect(BreadIdentity(crust) != BreadIdentity(Crust()))
    }
    
    @Test func nilIsOnlyTheSameAsNil() {
        #expect(BreadIdentity<String>(nil) == BreadIdentity<String>(nil))
        #expect(BreadIdentity<String>(nil) != BreadIdentity("A"))
    }
}
