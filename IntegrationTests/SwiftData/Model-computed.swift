import SwiftData

@Model
final class WithComputed {
    var width: Double = 0
    var height: Double = 0

    var area: Double {
        width * height
    }

    var doubled: Double {
        get { width * 2 }
        set { width = newValue / 2 }
    }
}
