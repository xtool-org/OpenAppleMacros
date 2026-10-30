import SwiftData

@Model
final class Settings {
    static var sharedName = "settings"
    let constant = 1
    private var count: Int = 0
    var inferred = "value"
    var computed: Int { count + 1 }
}
