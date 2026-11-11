import SwiftData

@Model
final class WithObservers {
    var count: Int = 0 {
        willSet {}
        didSet {}
    }
    var note: String = ""

    init() {}
}
