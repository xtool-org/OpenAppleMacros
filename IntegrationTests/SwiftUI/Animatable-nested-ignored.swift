// oam-postprocess: ./Animatable-normalize.py
import SwiftUI

@Animatable
struct OuterAnimatable {
    var amount: Double

    struct Nested {
        @AnimatableIgnored var label: String = "text"
    }
}
