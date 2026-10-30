import SwiftData

@Model final class `Default` {
    @Attribute(.unique) var `class`: String
    var `switch`: Int = 1
    init(_ name: String) { self.`class` = name }
}
