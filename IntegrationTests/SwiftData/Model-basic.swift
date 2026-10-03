import Foundation
import SwiftData

@Model
final class Draft {
    var content: String
    var creationDate: Date
    @Attribute(.unique) var id: UUID
    @Transient var scratch: Int = 0
    @Relationship(deleteRule: .cascade) var tags: [Tag] = []

    init(content: String) {
        self.content = content
        self.creationDate = Date()
        self.id = UUID()
    }
}

@Model
final class Tag {
    var title: String
    var count: Int?

    init(title: String) {
        self.title = title
    }
}
