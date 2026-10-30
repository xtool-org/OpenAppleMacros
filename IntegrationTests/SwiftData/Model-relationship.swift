import SwiftData

@Model final class Person {
    var name: String
    @Relationship(deleteRule: .cascade) var notes: [Note] = []
    init(name: String) { self.name = name }
}
@Model final class Note {
    var text: String
    init(text: String) { self.text = text }
}
