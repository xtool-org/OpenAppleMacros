import SwiftUI

@Animatable
struct ObservedAnimatable {
    var amount: Double = 0 {
        didSet {}
    }
}
