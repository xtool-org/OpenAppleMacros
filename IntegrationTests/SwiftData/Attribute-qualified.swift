import SwiftData

@Model
final class QualifiedAttributes {
    @SwiftData.Attribute(.unique) var id: Int = 0
    @SwiftData.Relationship(deleteRule: .cascade) var children: [QualifiedAttributes] = []
    @Attribute(.unique) var code: String = ""
    var name: String = ""

    init() {}
}
