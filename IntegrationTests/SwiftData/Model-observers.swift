import SwiftData

@Model
final class Observed {
    var count: Int = 0 { didSet { print(count) } }
    init() {}
}
