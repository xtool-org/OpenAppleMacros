import SwiftData

@Model
final class Person {
    var name: String
    var age: Int = 0
    var nickname: String?

    init(name: String) {
        self.name = name
    }
}
