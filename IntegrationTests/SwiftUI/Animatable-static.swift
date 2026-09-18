// oam-postprocess: ./Animatable-normalize.py
import SwiftUI

@Animatable
struct StaticAnimatable {
    var amount: Double

    // Apple includes static properties in their expansion
    static var shared: Double = 1
}
