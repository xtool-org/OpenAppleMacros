// oam-postprocess: ./Animatable-normalize.py
import SwiftUI

struct NestedValue: Animatable {
    var animatableData: Double
}

@Animatable
struct NestedAnimatable {
    var nested: NestedValue
    var amount: Double
}
