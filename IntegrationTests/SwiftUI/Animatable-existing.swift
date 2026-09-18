import SwiftUI

@Animatable
struct ExistingAnimatable: Animatable {
    var value: Double
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
}
