import SwiftData

@Model
final class WithStatic {
    static var counter: Int = 0
    class var kind: String { "generic" }
    var title: String = ""
}
