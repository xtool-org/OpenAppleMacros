import SwiftUI

@SwiftUI.Animatable
struct QualifiedAnimatable {
    var amount: Double
    @SwiftUI.AnimatableIgnored var label = "value"
}
