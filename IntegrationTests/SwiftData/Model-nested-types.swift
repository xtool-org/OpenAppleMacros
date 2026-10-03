import SwiftData

@Model
final class Outer {
    var title: String = ""

    struct Point {
        var x: Int = 0
    }

    @Model final class Inner {
        var value: Int = 0
    }
}
