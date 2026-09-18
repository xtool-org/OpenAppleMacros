import SwiftUI

@Animatable
struct MultipleAnimatable {
    var x, y: Double
    @AnimatableIgnored var label: String = "point"
    let origin: Double = 0
    var computed: Double { x + y }
}
